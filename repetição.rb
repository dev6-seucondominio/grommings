h1. Visão Geral

<pre><code class="ruby">
update
  modal_repeticao
    ghost:
      repeticao_atual:
        :todas
          descrito_abaixo
        :a_partir_desta
    persistida:
      repeticao_nova:

      repeticao_atual:
        todas:
          descrito_abaixo
        :a_partir_desta
  cobranca:
    ghost
      :somente_esta
        cob_service@update(id: '1:2')
          chamar cob_service@create
      :todas
        descrito_abaixo
      :a_partir_desta
    persistida
      :somente_esta
        cob_service@update(id: 4)
      :todas
        descrito_abaixo
      :a_partir_desta
</code></pre>


h1. Refatorar

h2. repetir_exceto deve atualizar no model de cobrança

quando
* persistir cobranca

h2. Create deve ser quebrado em 2 métodos

* create deve virar mass_create
* criar o create sem comportamento de criar em massa

h2. Refatorar Update (somente esta)

Deve chamar o cob_service@create caso for um ghost

h2. Refatorar cobranca@simular_repeticao

Deve simular a cobrança como um todo. Deve ser uma instancia com composicoes e etc

h2. rep_service@persistir_parcela

Migrar de cob_service  para rep_service

<pre>
def self.persistir_parcela(opts, parcela_id) # (opts, '1:90')
  cob = molde.simular_repeticao(3)
  ...
  cob.save
  resp[:pending_log] = cob
  resp[:cobranca] =  cob
  return [status, resp]
end
</pre>


h2.Atualizar boletos_service

Adequar para realidade do rep_service@persistir_parcela

h2. Atualizar quitar para nova realidade

front quitando
<pre>
cob_service@update
  -> cob_service@micro update
  -> cob_service@quitar
      monta params através de montar_recebimentos
      cob_service@update
        if ghost
          ideia chamar o create
</pre>


h2. Refatorar atualizar todas repetições

<pre><code class="ruby">
todas:
  cob_service@update(molde)
    -> rep_service@reprocessar_repeticoes(...) if repeticao_update
      -> return
          obj = {
            items: ...,
            # atualizar_persistida: ...,
            atualizar_repeticao: ...,
            removed_ids: ...
          }
</code></pre>

h2. Refatorar atualizar a partir desta

<pre><code class="ruby">
  a_partir_desta
    cob_service@update
      if update_type == 'a_partir_desta' && cobranca_id.split(':').last != 1
        -> rep_service@atualizar_a_partir_desta(opts, cobranca_id, params)
      -> criar novo familia
        -> persistir parcela: cob_service@update
        -> nova repeticao:
            -> descontinuar: set_repeticao_attrs
            -> create_repeticao
        -> set_quantidade
      -> familia atual
        -> set_quantidade
      -> reprocessar_repeticoes(...)
</code></pre>

h2. Analisar e refatorar caso necessário cancelar e restaurar

* somente esta
* a partir esta
* todas

h1. Descontinuar

h2. persitir cobrança em massa

h2. repeticao_cobranca_service@update_repetir_exceto, pois o model já faz esse trabalho


