- Cobranças criadas que não estão dentro do filtro estão sem poder fazer ações

- Existe um padrão em observar processo em repeticao_cobrancas_service e boletos_service
  Talvez possamos passar um opt emitir_boleto em cobrancas_service
  Talvez possamos usar o tipo de processo (boleto ou repeticao) e fazer a diferença deles lá, que não é mt

----   Resolvidos -------

- Alterado cobranca@buscar para quando pesquisar pelo codigo trazer mesmo se estiver fora do periodo da repetição
- Barra de progressão emitindo somente o item atualizado em questão, e foi corrigido para chegar ao 100%
- Atualizar a partir desta foi resolvido,
  so falta a parte do Diego H. em
    cobranca_service@update e repeticao_cobranca_service@reprocessar_persistidas

---- Tarefas em execução ----
