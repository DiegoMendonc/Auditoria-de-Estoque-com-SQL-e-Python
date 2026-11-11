# Auditoria de estoque com SQL e Python

**Em construção** · Projeto de portfólio de auditoria interna com dados fictícios.

## Resumo executivo

O projeto simula um inventário da Horizonte Suprimentos. O objetivo é verificar se o saldo registrado no ERP na data de corte coincide com a contagem física feita nos depósitos. O SQL será usado para reconstruir os saldos e classificar as diferenças. O Python executará a análise e exportará as exceções e os indicadores por depósito.

[Norma interna](norma-interna-inventario.md) · [Base do ERP](base.sql) · [Caderno de contagem em PDF](output/pdf/caderno-contagem-estoque.pdf) · [Transcrição da contagem](contagem-fisica.sql)

## Objetivo e escopo

- **Risco avaliado** — saldos incorretos podem afetar o reabastecimento, a disponibilidade de materiais e os registros de estoque.
- **População** — 480 combinações de material e depósito, incluindo saldo zero. Cada combinação representa uma unidade de análise.
- **Depósitos** — Norte e Sul. Todos os materiais usam a unidade UN.
- **Período** — saldo de abertura em 01/09/2026 às 00h e inventário em 30/09/2026 às 18h, no horário de Brasília.
- **Limites** — o exercício testa quantidades e corte de lançamentos. Custos de referência estão disponíveis para uma análise posterior da exposição. As causas e os ajustes dependeriam de evidência complementar.

## Critério de auditoria

A [NOR-EST-001](norma-interna-inventario.md) define como comparar o saldo do ERP com o caderno de contagem. Some entradas e subtraia saídas registradas até o corte, inclusive. Calcule a diferença como **contagem física menos saldo esperado**. Uma diferença negativa é falta e uma positiva é sobra. Campo em branco é contagem pendente. Zero é uma quantidade válida.

Use `registrado_em` para reconstruir o saldo disponível no ERP no instante do inventário. Use `ocorrido_em` para investigar movimentos físicos anteriores ao corte lançados depois dele. Os três lançamentos `MOV-036001`, `MOV-036002` e `MOV-036003` foram incluídos para testar essa distinção.

## Base e evidência

| Fonte | Conteúdo | Registros |
| --- | --- | ---: |
| `materiais` | SKU, descrição, categoria, unidade e custo de referência | 240 |
| `depositos` | Depósitos Norte e Sul | 2 |
| `saldos_iniciais` | Saldo de abertura por material e depósito | 480 |
| `movimentacoes` | Documento, quantidade, tipo e horários de ocorrência e registro | 35.928 |
| `contagens_fisicas` | Quantidade observada e código da folha de origem | 480 |

O PDF simula a ficha preenchida antes do lançamento no ERP. São **12 folhas de 40 itens**, sem indicação de saldo sistêmico. A transcrição em SQL preserva o código da folha e representa campos em branco com `NULL`. Na simulação, os valores físicos foram gerados a partir do saldo reconstruído com diferenças intencionais para exercitar a análise.

## Como carregar no DBeaver

1. Crie uma conexão SQLite para um arquivo vazio chamado `auditoria_estoque.db`.
2. Abra [base.sql](base.sql) nessa conexão e execute o script completo com **Alt+X**.
3. Abra [contagem-fisica.sql](contagem-fisica.sql) na mesma conexão e execute com **Alt+X**. Use cada script uma vez por banco novo.
4. Confira as contagens com **Ctrl+Enter**.

```sql
SELECT
    (SELECT COUNT(*) FROM movimentacoes) AS movimentos,
    COUNT(*) AS linhas_do_caderno,
    COUNT(quantidade_contada) AS contagens_preenchidas
FROM contagens_fisicas;
```

O resultado esperado é **35.928 movimentos, 480 linhas do caderno e 458 contagens preenchidas**. Use estes totais de referência para validar a futura conciliação.

| Classificação | Combinações |
| --- | ---: |
| Conforme | 385 |
| Falta | 40 |
| Sobra | 33 |
| Sem contagem registrada | 22 |
| **Total no escopo** | **480** |

## Checklist

- [x] Definir objetivo, riscos, escopo e data de corte.
- [x] Documentar o critério de inventário na norma fictícia.
- [x] Gerar a base SQLite com lançamentos próximos ao corte.
- [x] Gerar o caderno de contagem e sua transcrição rastreável.
- [ ] Mapear as chaves do modelo e conferir a população.
- [ ] Escrever a conciliação em SQL, mantendo uma linha por material e depósito.
- [ ] Testar os lançamentos de fronteira e reconciliar as classificações.
- [ ] Automatizar a execução e as exportações com Python.
- [ ] Comparar taxas de exceção por depósito e investigar dois casos.
- [ ] Publicar o relatório, o painel e um resumo para o LinkedIn.

As Normas Globais de Auditoria Interna do IIA orientam a estrutura do exercício, em especial objetivos e escopo (13.3), critérios (13.4), documentação (14.6) e comunicação final (15.1).
