# Migrates

## Remover migrate CreateFunctionParcelarCobranca

```
Migrate removida por que será criado Serviços para resolver problemas de migrations futuros
```

# Serviços

```
Atenção: Rever as funções/views/types pois antes estava sendo usado o simbolo '%()'
Devemos remove-ló e subistituir por '%q{}'

Motivo: o primeiro usado não garante total fidelidade,
        e se usamos uma regexp com '\d' ele transforma isso em 'd'
        o que pode traser resultados incompriensíveis.
```

## Adicionar o type removida da migration em Sistema::Db::TypesService

```ruby
module Sistema
  module Db
    # Possui instrucoes para criar e remover todas as types do sistema
    class TypesService < Base
      TYPES = {
        date_table: {
          destroy: %q{
            DROP TYPE IF EXISTS DATE_TABLE;
          },
          create: %q{
            CREATE TYPE DATE_TABLE AS (new_maturity DATE, new_reference DATE);
          }
        }
      }

      ...
    end
  end
end
```

```
Repensar no nome do type 'date_table'
```

## Adicionar a função removida da migration em Sistema::Db::FunctionsService

```ruby
module Sistema
  module Db
    # Possui instrucoes para criar e remover todas as functions do sistema
    class FunctionsService < Base
      FUNCTIONS = {
        generate_recurrences: {
          destroy: %q{
            DROP FUNCTION IF EXISTS
              generate_recurrences(timestamp without time zone, timestamp without time zone, interval)
            ;
          },
          create: %q{
            CREATE OR REPLACE FUNCTION generate_recurrences(
              start_date TIMESTAMP, end_date TIMESTAMP, duration INTERVAL
            )
              RETURNS setof TIMESTAMP
              LANGUAGE plpgsql STABLE
              AS $$
            DECLARE
              type TEXT := SUBSTRING(duration::text, '(mon|month|year|day)$');

              -- Aux
              last_day_month BOOLEAN;
              last_day       INTEGER;
              day_date       INTEGER := EXTRACT(DAY FROM start_date);
            BEGIN
              IF (((type = 'month') OR (type = 'mon')) AND (day_date > 28)) THEN
                last_day_month := EXTRACT(MONTH FROM (start_date + '1 day'::interval)) <>
                                  EXTRACT(MONTH FROM start_date);

                IF (last_day_month IS TRUE) THEN
                  RETURN QUERY
                    SELECT
                      (DATE_TRUNC('MONTH', generated_date) + INTERVAL '1 month - 1 day')
                    FROM
                      generate_series(start_date, end_date, duration) generated_date
                    ;
                ELSE
                  RETURN QUERY
                    SELECT
                      CASE
                        WHEN (EXTRACT(DAY FROM (DATE_TRUNC('MONTH', generated_date) + INTERVAL '1 month - 1 day'))::integer > day_date) THEN
                          (to_char(generated_date, 'YYYY-MM-') || day_date::text)::TIMESTAMP
                        ELSE
                          (DATE_TRUNC('MONTH', generated_date) + INTERVAL '1 month - 1 day')
                        END
                    FROM
                      generate_series(start_date, end_date, duration) generated_date
                    ;
                END IF;
              ELSE
                RETURN QUERY
                  SELECT
                    generate_series(start_date, end_date, duration) generated_date
                  ;
              END IF;
            END;
            $$;
          }
        },
        parcelar_cobranca: {
          destroy: %q{
            DROP FUNCTION IF EXISTS
              parcelar_cobranca(timestamp without time zone, timestamp without time zone, boolean)
            ;
          },
          create: %q{
            CREATE OR REPLACE FUNCTION parcelar_cobranca(
              load_at TIMESTAMP,
              load_to TIMESTAMP,
              slash_ghost BOOLEAN
            )
              RETURNS SETOF parcelada_cobrancas
              LANGUAGE plpgsql STABLE
              AS $$
            DECLARE
              cobranca  parcelada_cobrancas;

              -- Maturity
              start_maturity TIMESTAMPTZ;
              ends_maturity  TIMESTAMPTZ;
              start_time_maturiry TEXT;

              -- Reference
              start_reference TIMESTAMPTZ;
              ends_reference  TIMESTAMPTZ;
              start_time_reference TEXT;

              -- Aux
              next_date     DATE_TABLE;
              total_parcela INTEGER;

              parcela       INTEGER;
              repetir_arr   TEXT[];
              each_for      INTEGER;
              _times        INTEGER;
              type          TEXT;
            BEGIN
              FOR cobranca IN
                SELECT
                  *
                FROM
                  parcelada_cobrancas
                WHERE
                  slash_ghost IS TRUE AND
                  (
                    (vencimento >= load_at AND
                      vencimento <= load_to AND
                      parcelador_id IS NULL) OR
                    parcelador_id IS NOT NULL
                  ) OR
                  slash_ghost IS FALSE
                LOOP
                  -- Next if not repeat
                  IF cobranca.periodo IS NULL THEN
                    RETURN NEXT cobranca;
                    CONTINUE;
                  END IF;

                  -- Get regexp of cobranca
                  repetir_arr := regexp_matches(
                    cobranca.periodo, '^(each) (\d*) (month|year|day)( \d+)*( times)*$'
                  );

                  each_for  := repetir_arr[2];
                  type      := repetir_arr[3];
                  _times    := repetir_arr[4];

                  -- Error if invalid regexp
                  IF (each_for IS NULL) OR (type IS NULL) THEN
                    RAISE EXCEPTION 'Comand (%) not found', cobranca.periodo;
                  END IF;

                  IF (_times IS NULL) AND (load_at IS NULL) AND (load_to IS NULL) THEN
                    RAISE EXCEPTION 'Invalid parameters';
                  END IF;

                  start_maturity := to_char(cobranca.vencimento, 'YYYY-MM-DD')::text::timestamptz;
                  start_time_maturiry := start_maturity::time::text;

                  start_reference := (to_char(cobranca.mes_referencia::timestamp, 'YYYY-MM-') || to_char(start_maturity, 'DD')::TEXT)::timestamptz;
                  start_time_reference := start_reference::time::text;

                  IF (_times IS NOT NULL) THEN
                    total_parcela := _times;
                    ends_maturity := start_maturity::timestamp + ((total_parcela * each_for)-1 || ' ' || type)::interval;
                    ends_reference := start_reference::timestamp + ((total_parcela * each_for)-1 || ' ' || type)::interval;
                  ELSE
                    total_parcela := NULL;
                  END IF;

                  IF (_times IS NULL) OR (load_to < ends_maturity AND slash_ghost IS TRUE) THEN
                    ends_maturity := load_to::timestamp;
                    ends_reference := (load_to - (start_maturity - start_reference))::timestamp;
                  END IF;

                  parcela := 0;
                  FOR next_date IN
                    SELECT
                      generate_recurrences(start_maturity::timestamp, ends_maturity::timestamp,
                                      (each_for || ' ' || type)::interval
                                     ) new_maturity,
                      generate_recurrences(start_reference::timestamp, ends_reference::timestamp,
                                      (each_for || ' ' || type)::interval
                                     ) new_reference
                    LOOP
                      cobranca.vencimento := (next_date.new_maturity || ' ' || start_time_maturiry)::timestamp;
                      cobranca.mes_referencia := (next_date.new_reference || ' ' || start_time_reference)::timestamp;
                      cobranca.origem := 'repeticao';

                      parcela := 1 + parcela;
                      IF cobranca.vencimento < load_at AND slash_ghost IS TRUE THEN
                        CONTINUE;
                      END IF;

                      IF total_parcela IS NOT NULL THEN
                        cobranca.parcela := parcela;
                        cobranca.parcela_qtd := total_parcela;
                      ELSE
                        cobranca.parcela := parcela;
                      END IF;

                      RETURN NEXT cobranca;
                  END LOOP;
                END LOOP;
              RETURN;
            END;
            $$;
          }
        }
      }
    end
  end
end
```

## Adicionar a view removida da migration em Sistema::Db::ViewsService

```ruby
module Sistema
  module Db
    # Possui instrucoes para criar e remover todas as functions do sistema
    class ViewsService < Base
      VIEWS = {
        ...
        parcelada_cobrancas: {
            destroy: %q{
              DROP VIEW IF EXISTS parcelada_cobrancas;
            },
            create: %q{
              CREATE VIEW parcelada_cobrancas AS
                SELECT
                  financeiro_parceladores.molde_id,
                  financeiro_parceladores.periodo,
                  financeiro_parceladores.canceladas,
                  financeiro_cobrancas.*
                FROM
                  financeiro_cobrancas
                LEFT JOIN
                  financeiro_parceladores ON financeiro_parceladores.id = financeiro_cobrancas.parcelador_id
              ;
            }
        }
      }

      ...
    end
  end
end
```

# Show de cobrança

## Adicionar tooltip informando a frequencia de repetição

```html
  <span ng-if="cobranca.parcela"
        class="snowrap sc-m-r-md" sc-tooltip="{{cobranca.parcelador.info}}" >
    {{ cobranca.parcela }}/{{ cobranca.parcela_qtd || '&infin;' }} </span>
```

## Adicionar paragrafo no show para printar o Repetição

file: app/assets/templates/gerenciar/cd/financeiro/cobrancas/show.html

```html
<p ng-if="!cobranca.persistida" class="sc-text-gray">
  Repetição: <span class="sc-text-blue sc-p-l-sm">{{cobranca.parcela}}/{{cobranca.parcela_qtd || '&infin;'}} ({{cobranca.parcelador.info}})</span>
</p>
```

## Movido o metodo parcelador do to_frontend_obj para slim_obj

```
foi nescessário pois irá mostrar no tooltip as informações da repetição
```

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
