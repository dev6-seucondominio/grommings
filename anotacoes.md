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

[] A opção de editar a repetição irá para o menu opções da cobrança.
  Ao escolher editar a repetição o usuário verá o modal contendo as opções de repetição.
    Rádio *repetir cobrança?*
      *Repetir cobrança a cada*
      *Quantidade definida?*
      *Quantidade de vezes*
    Isso de acordo com o definido na primeira cobrança da série.

  Ao manter em repetir cobrança e clicar em salvar o modal de decisões deve abrir onde:
    A opção de editar somente esta deverá estar desabilitada
    A opção de editar esta e as futuras limitará a série de cobranças e começar uma nova a partir da que esta sendo editada(pode ser emitir um alert para isso)
    A opção de editar todas matará cobranças não persistidas e sem recebimentos e criará uma nova séria a partir dessa.

  Caso o usuário defina que não irá repetir.
    A opção de editar somente esta virá desabilitada
    A opção de editar esta e as futuras limitará a série atual matará todas as futuras.
    A opção de alterar todas virá desabilitada
