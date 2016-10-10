def destroy_ocorrencias(opts)
  cliente = opts[:cliente_id]
  com_recebimentos = opts[:com_recebimentos].nil? ? false : opts[:com_recebimentos]

  ActiveRecord::Base.transaction do
    Financeiro::Boleto.do_cliente(cliente).map(&:destroy!)
    Financeiro::BoletoOcorrencia.do_cliente(cliente).map(&:destroy!)
    Financeiro::Remessa.do_cliente(cliente).map(&:destroy!)
    Financeiro::Retorno.do_cliente(cliente).map(&:destroy!)

    if com_recebimentos
      Financeiro::Recebimento.do_cliente(cliente).each do |rec|
        rec.destroy!

        cobranca.quitada_em = nil unless cobranca.quitada_no_credito?
        cobranca.save!
      end
    end
  end
end

def get_boletos(type, limit=nil)
  boletos = Financeiro::Boleto.includes(ocorrencias: [:boleto, :banco]).order(:data_vencimento).select{ |b| b.status_registro == type }

  boletos = boletos.take(limit) if limit.present?
  boletos
end

def generate_header(opts)
  conta   = "#{opts[:conta_corrente]}0".rjust(8, '0').limit(-8, 8)
  agencia = opts[:agencia].to_s.rjust(4, '0').limit(-4, 4)

  text  = "02RETORNO01COBRANCA       #{agencia}#{conta}        SEU CONDOMINIO LTDA-ME        341BANCO ITAU S.A.24111501600BPI50300351115"
  text << ''.rjust(275, ' ')
  text << "000001\n"
  text
end

def generate_detalhes(opts, boletos)
  text    = ''

  conta    = "#{opts[:conta_corrente]}0".rjust(8, '0').limit(-8, 8)
  agencia  = opts[:agencia].to_s.rjust(4, '0').limit(-4, 4)
  tarifa   = ('%.2f' % opts[:tarifa]).remove(/[,.,]/).rjust(13, '0').limit(-13, 13)
  pagament = ('%.2f' % opts[:valor_recebimento].to_f).remove(/[,.,]/).rjust(13, '0').limit(-13, 13)
  codigo_ocorrencia = opts[:codigo_ocorrencia].to_s.rjust(2, '0').limit(-2 ,2)

  boletos.each_with_index do |bo, i|
    item = (i + 2).to_s.rjust(6, '0').limit(-6, 6)

    text << "10214488585000145#{agencia}#{conta}"
    text << ''.rjust(33, ' ')

    # se for sem sequencia, iremos setar um virtual só para simular um registro
    if bo.sequencia.to_i == 0
      bo.sequencia = Faker::Number.number(4)
      bo.nosso_numero = bo.boleto_build.nosso_numero_boleto.somente_numeros
    end

    cobranca = bo.sequencia.to_s.rjust(8, '0').limit(-8, 8)
    nosso    = bo.nosso_numero.to_s.rjust(12, '0').limit(-12, 12)
    n_doc    = bo.numero_documento.to_s.rjust(10, '0').limit(-10, 10)
    text << "#{cobranca}            #{nosso}             I#{codigo_ocorrencia}180716#{n_doc}#{cobranca}"

    vencimen = bo.data_vencimento.strftime('%d%m%y')
    valo_doc = ('%.2f' % bo.valor).remove(/[,.,]/).rjust(13, '0').limit(-13, 13)
    text << "            #{vencimen}#{valo_doc}34146839  "

    text << "#{tarifa}00000000000000000000000000000000000000000000000000000000000000000"

    pagament = ('%.2f' % (bo.valor.to_f - opts[:tarifa].to_f)).remove(/[,.,]/).rjust(13, '0').limit(-13, 13) if opts[:valor_recebimento_do_boleto] # usar valor do boleto
    text << "#{pagament}00000000000000000000000000         "
    text << "00000000000000000000000RODRIGO MENDONCA                                     01000000         #{item}\n"
  end

  text
end

def generate_trailer(opts, boletos)
  count_bo = (boletos.count + 2).to_s.rjust(6, '0').limit(-6, 6)

  text  = "9201341          000000000000000000000000000000          000000000000000000000000000000"
  text << "                                                  000000000000000000000000000000          "
  text << "000000000000000000000000000000000000000000000000000000000"
  text << ''.rjust(160, ' ')
  text << "#{count_bo}"
end

def gerar_retornos(opts)
  retornos = []

  type, size = opts.values_at(:status_boleto, :limit_boleto)
  boletos = get_boletos(type, size).group_by{|b| [b.agencia, b.conta_corrente] }
  boletos.each do |agecont, bots|
    opts     = opts.merge(agencia: agecont[0], conta_corrente: agecont[1])

    header   = generate_header(opts)
    detalhes = generate_detalhes(opts, bots)
    trailer  = generate_trailer(opts, bots)

    retornos << "#{[header, detalhes, trailer].join('')}\n"
  end

  retornos
end

# destruindo todas as ocorrencias, boletos, remessas e retornos
# destroy_ocorrencias(com_recebimentos: true, cliente_id: 1)

opts = {
  tarifa: 7,
  valor_recebimento: 10,
  valor_recebimento_do_boleto: true, # usar o valor do boleto como recebimento (pagamento do boleto completo)
  status_boleto: :aguardando_remessa,
  limit_boleto: nil, # 10
  codigo_ocorrencia: '06' # '06' -> pagamentos, '02' -> confirmar registro, '03' -> registro regeitado... Verificar codigo no payment conf do banco desejado
}

# buscar boletos do tipo :aguardando_retorno, :aguardando_conciliacao, :aguardando_remessa, etc... e gerar retorno para eles agrupado por conta e agencia
retornos = gerar_retornos(opts)

retornos.each do |r|
  puts "#{''.rjust(150, '-')}\n"
  puts r
  puts "#{''.rjust(150, '-')}\n"
end
