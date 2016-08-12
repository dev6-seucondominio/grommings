[] Cancelar de plano conta automatico não cancela kk

[] Trocar cancelar para remover em remessas

[] Criar validação em conta_banco
  Colocar zeros a esquerda da agencia e conta de cada conta_banco
  Necessário pois retorno trabalha com zeros a esquerda.. e quando tentamos anexar um retorno,
    dá erro de conta não encontrada por causa de 1 zero que seja

[] Validar quando tem remessa pendente e é chegado um retorno para ela
  isso pode acontecer se por acaso o retorno de outro sistema traser o boleto que bata com uma de nossas cobrancas :O

[] Protejer boletos com nosso número que não seja livre
  solução
    Remover codigo de barra, linha digitavel e codigo de barras
      aparecer na linha digitavel que o boleto não está disponivel no momento
        VERMELHO (DANGER)

[] Testar params_to_hash para loop de strings

[] Substituir parameter_as_hash para params_to_hash
  testar com filtro

[] Payment: Verificar data de retorno.
