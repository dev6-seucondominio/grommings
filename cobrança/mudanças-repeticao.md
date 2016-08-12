# Show de cobrança

## Alterações em parcelado (Repetição < Parcelamento)

### to_frontend_obj

```
Adicionado quantidade e info usados para o show
```

```ruby
    def to_frontend_obj
      attrs = mapear_atributos(%w(periodo))
      attrs[:quantidade] = get_quantidade
      attrs[:info] = periodo_info

      attrs
    end
```

### Adicionando metodos para compor o to_frontend_obj

```ruby
Adequar frequencia, periodo e quantidade no model: parcelador.rb
frequencia = 4
quantidade = 2
periodo    = 3
```

```ruby
    ...


    def get_quantidade
      return if periodo.empty?
      periodo.split(params_split).compact_full[1]
    end

    # periodo
    def get_type_date
      return if periodo.empty?
      periodo.split(params_split).compact_full[2]
    end

    def periodo_info
      "Repete a cada #{get_quantidade} #{translate_type_date}"
    end

    # repensar nessa função pois não consegui (diego) ultilizar uma regexp :'(
    def translate_type_date
      return 'dias' if get_type_date == 'day'
      return 'meses' if get_type_date == 'month'
      return 'anos' if get_type_date == 'year'
      nil
    end

    # private

    # tratando a repetição infinita (regexp não consegui pegar só a metade)
    # utilizar somente um tipo de regex 0 times
    def params_split
      periodo.split(PERIOD_FORMAT_RE).many? ? PERIOD_FORMAT_RE : ' '
    end

    ...
```

# Cobrança com limite de repetição indefinida

## Montar parcelador no front

```
Os 'infinitos' não estão sendo listados
```


```
Analizar se este metodo esta no local correto, deveria estar no front ?????
```

file: app/assets/javascripts/gerenciar/cd/financeiro/controllers/cobrancas/form_ctrl.coffee

```diff
        mountParcelador: ->
-        # each 1 month 12 times
+        # each 1 month 12 times | each 1 month
         repetir = @params.repetir
         return {} unless repetir

-        repeticao = "each #{repetir.frequencia} #{repetir.periodo} #{repetir.quantidade} times"
+        repeticao = "each #{repetir.frequencia} #{repetir.periodo}"
+        repeticao <<  "#{repetir.quantidade} times" if repetir.quantidade
```

## Adicionar filtro no show

file: app/assets/javascripts/gerenciar/cd/financeiro/controllers/cobrancas/item_ctrl.coffee

```diff
       $s.cobranca.carregando = true
       Cobranca.show
         id: $s.cobranca.id
+        filtro: $s.filtro.params
         (data)->
           $s.cobranca = angular.extend $s.cobranca, data
           $s.cobranca.carregando = false
```

## Alterar forma de buscar os fantasmas no show

file: app/controllers/gerenciar/cd/financeiro/cobrancas_controller.rb

```diff
     # buscar fantasmas
-    ghost_cob = model.do_cliente(current_cliente).repeticoes(params[:id]).first
+    params_repeat = {}
+    params_repeat[:filtro], params_repeat[:id] = params.values_at(:filtro, :id)
+    ghost_cob = model.do_cliente(current_cliente).repeticoes(params_repeat).first
     return render json_service.responda_nao_encontrado unless ghost_cob

     return respond_to do |format|

```

## Alterar o scope repetições

```
Analizar, os parametros de inicio e fim,
pois quando criamos uma nova cobranca se não estivermos no mesmo mes,
a cobrança não é encontrada D:
```

file: app/models/financeiro/cobranca.rb

```diff
     scope :repeticoes, lambda { |parcelas|
-      parcelas = [parcelas.presence].compact.flatten
+      filtro = parcelas.delete(:filtro) || {}
+      filtro = params_to_hash(filtro)
+
+      parcelas = [parcelas.presence.try(:values)].compact.flatten
       return all unless parcelas
       fail "invalid argument #{parcelas}" if parcelas.empty?

@@ -374,13 +377,13 @@ module Financeiro
                       " #{table_name}.parcela = ? AND NOT" \
                       " #{table_name}.canceladas @@ '?')") # remove canceladas

-      filtro = {
+      filtro_repeat = {
         slash_ghost: false,
-        inicio:      cobrancas.first.vencimento,
-        fim:         cobrancas.last.vencimento
+        inicio:      filtro[:inicio],
+        fim:         filtro[:fim]
       }

-      all.com_repeticoes(filtro).where(sql.join(' OR '), *args.compact.flatten)
+      all.com_repeticoes(filtro_repeat).where(sql.join(' OR '), *args.compact.flatten)
     }
```
