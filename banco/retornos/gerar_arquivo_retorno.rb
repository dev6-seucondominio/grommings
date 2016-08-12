text = "02RETORNO01COBRANCA       014700109060        SEU CONDOMINIO LTDA-ME        341BANCO ITAU S.A.24111501600BPI50300351115                                                                                                                                                                                                                                                                                   000001\n"

boletos = Financeiro::Boleto.do_cliente(1).mais_recentes.limit(50)

boletos.each_with_index do |bo, i|
  item = (i + 2).to_s.rjust(6, '0').limit(-6, 6)
  puts "#{item} : #{bo.nosso_numero}\n" * 10

  cobranca = bo.cobranca_id.to_s.rjust(8, '0').limit(-8, 8)
  nosso    = bo.nosso_numero.to_s.rjust(12, '0').limit(-12, 12)

  text = text + "10214488585000145014700109060                                 #{cobranca}            #{nosso}             I02180716          #{cobranca}            200716000000000010034146839  000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000         00000000000000000000000RODRIGO MENDONCA                                     01000000         #{item}\n"
end

count_bo = (boletos.count + 2).to_s.rjust(6, '0').limit(-6, 6)

text = text + "9201341          000000000000000000000000000000          000000000000000000000000000000                                                  000000000000000000000000000000          000000000000000000000000000000000000000000000000000000000                                                                                                                                                                #{count_bo}"

puts text
