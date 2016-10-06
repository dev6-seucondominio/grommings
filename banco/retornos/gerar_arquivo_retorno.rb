Financeiro::Boleto.do_cliente(3).destroy_all
Financeiro::BoletoOcorrencia.do_cliente(3).destroy_all
Financeiro::Remessa.do_cliente(3).destroy_all
Financeiro::Retorno.do_cliente(3).destroy_all

###########################################

boletos = Financeiro::Boleto.do_cliente(3).mais_recentes.limit(50)

agencia = boletos.first.agencia.to_s.rjust(4, '0').limit(-4, 4)
conta_c = "#{boletos.first.conta_corrente}0".rjust(8, '0').limit(-8, 8)

text = "02RETORNO01COBRANCA       #{agencia}#{conta_c}        SEU CONDOMINIO LTDA-ME        341BANCO ITAU S.A.24111501600BPI50300351115                                                                                                                                                                                                                                                                                   000001\n"

boletos.each_with_index do |bo, i|
  item = (i + 2).to_s.rjust(6, '0').limit(-6, 6)

  cobranca = bo.sequencia.to_s.rjust(8, '0').limit(-8, 8)
  nosso    = bo.nosso_numero.to_s.rjust(12, '0').limit(-12, 12)
  n_doc    = bo.numero_documento.to_s.rjust(10, '0').limit(-10, 10)
  vencimen = bo.data_vencimento.strftime('%d%m%y')
  valo_doc = bo.valor.to_s.remove(/[,.,]/).rjust(13, '0').limit(-13, 13)
  agencia  = bo.agencia.to_s.rjust(4, '0').limit(-4, 4)
  conta_c  = bo.conta_corrente.to_s.rjust(8, '0').limit(-8, 8)

  text = text + "10214488585000145#{agencia}#{conta_c}                                 #{cobranca}            #{nosso}             I06180716#{n_doc}#{cobranca}            #{vencimen}#{valo_doc}34146839  000000000070000000000000000000000000000000000000000000000000000000000000000000070230000000000000000000000000000000000         00000000000000000000000RODRIGO MENDONCA                                     01000000         #{item}\n"
end

count_bo = (boletos.count + 2).to_s.rjust(6, '0').limit(-6, 6)

text = text + "9201341          000000000000000000000000000000          000000000000000000000000000000                                                  000000000000000000000000000000          000000000000000000000000000000000000000000000000000000000                                                                                                                                                                #{count_bo}"

puts text
