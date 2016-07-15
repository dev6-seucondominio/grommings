Se a repetição a ser editada for infinita e a opção for Atualizar a partir desta cria um novo molde e o antigo começa a ter limite
  ex.: each 1 month
         editou na parcela 10
       repetir_a_cada fica
         each 1 month 9 times
       e gera nova cobranca a partir do 10 como
         each 1 month

Temos um problema de performance na função de repetição
  Vejamos, temos uma repetição infinita.. 'each 1 day' por exemplo.

  problemas...

  - moldes (xii...)
    A função executa a seguinte condição no select

    input_date >= inicio AND
    input_date <= fim OR
    (parcelamento_id IS NULL OR
     id = ANY(moldes))

    Mesmo com os moldes fazendo parte da condição.. ele é apenas uma segunda opção, mais quanto aos moldes de outros cliente?, ele traria tudo.. porque pode estar no intervado de inicio e fim do vencimento!!

  - generate_recurrences (danger)
    Bom, pensamos:
      - temos uma cobrança com o vencimento para '2016-07-01'
      - temos um fim para '2020-07-01'

    * o que acontece hoje (filtro de '2016-07-01 a 2020-07-01')
      generate_recurrences vai gerar um loop a partir do mes 07 de 2016 até o mes 07 de 2020

      isso equivale a 1.461 dias

      então teriamos além das cobranças normais, mais 1.461 cobranças sendo repetidas.. até ai tudo bem, porque queremos tudo isso mesmo..

      mas.. e se o filtro fosse de '2020-01-01' a '2020-07-01', lembre-se que o vencimento ainda é '2016-07-01' (passou já 4 anos ( :-D ))

      a função geraria mesmo assim, uma sequencia de '2016-07-01 a 2020-07-01'

      isso ainda equivale a 1.461 dias... quando deveria ser apenas 182 ( :-O )

      a possível solução seria gerar uma sequencia a partir de '2020-01-01' ao invés de '2016-07-01', mas isso implica no calculo de parcelas para saber qual é a parcela daquele exato dia ( (:-3) = Good look)

