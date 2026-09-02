# RADAR

Marketing + comercial por cliente: você cadastra clientes, dentro de cada um cadastra os períodos com os dados de cada mídia (Google Ads, Meta Ads, TikTok Ads, ChatGPT Ads, ou outra) e os resultados comerciais, e o app gera relatório com gráficos, comparativos e um chat com IA (via seu n8n) pra conversar sobre esses números.

## Como funciona

- **Home**: lista de clientes, igual ao ESTEIRA e ao CARTEIRA.
- **Dentro do cliente**, 3 abas:
  - **Períodos**: cadastre um período (semana, quinzena, mês — você define) com os dados comerciais (qualificados, reuniões, propostas, vendas, receita). Ao criar, você já cai direto na tela do período pra adicionar as mídias.
  - **Relatório**: seletor de visão no topo — **Visão geral** (soma todas as mídias + funil comercial completo) ou uma mídia específica (Google Ads, Meta Ads, TikTok Ads, ChatGPT Ads, ou qualquer "Outra" que você tenha nomeado). Cada visão tem tabela de métricas com semáforo, gráficos (investimento x receita, ROAS, leads x vendas, investimento por mídia), e — só na visão geral — os pontos de atenção gerados automaticamente.
  - **Conversar com a IA**: chat sobre a visão de relatório selecionada no momento (aparece escrito no topo do chat qual visão está em conversa).
- Dentro de um período, a aba **Marketing por mídia** é onde você cadastra o investimento/impressões/cliques/leads de cada plataforma separadamente.
- Exclusão sempre pede pra digitar **DELETE**.

## Por que a receita/vendas não é dividida por mídia

Isso é proposital: dividir vendas e receita por canal exige um modelo de atribuição (qual anúncio realmente "causou" a venda quando o lead passou por vários toques) que esse app não tenta resolver. Por isso o funil comercial (qualificado → reunião → proposta → venda → receita) fica só na Visão Geral, como um resultado do negócio como um todo; cada mídia mostra até onde ela é diretamente responsável: investimento, impressões, cliques e leads gerados.

## Passo 1 — Supabase

1. [supabase.com](https://supabase.com) → **New project**
2. Anote **Project URL** e **anon public key**
3. **SQL Editor** → cole `schema.sql` → **Run** (se você tinha a v1 do RADAR, esse script já remove a tabela antiga e recria do zero)
4. **Authentication → Users → Add user**, marcando **Auto Confirm User**

## Passo 2 — n8n (fluxo de IA)

Igual à v1 — se você já montou o workflow antes, não precisa mexer, só o formato do payload ganhou dois campos novos:

```json
{
  "question": "por que o CAC subiu?",
  "history": [ { "role": "user", "content": "..." }, { "role": "assistant", "content": "..." } ],
  "clientName": "Dra. Larissa",
  "reportView": "Visão geral",
  "report": {
    "periodLabel": "Semana 1 — jan/2026",
    "periodStart": "2026-01-01",
    "periodEnd": "2026-01-07",
    "previousPeriodLabel": "Semana 4 — dez/2025",
    "metrics": [ { "key": "cac", "label": "CAC", "current": 312.5, "previous": 280.0, "deltaPct": 0.116, "status": "red" } ],
    "bullets": [ "CPL caiu mas o CAC subiu — o problema provável não está no tráfego." ]
  }
}
```

Se ainda não montou: Webhook (POST) → checar header `X-Radar-Secret` → nó de IA usando `{{$json.body.report}}`, `{{$json.body.clientName}}` e `{{$json.body.question}}` → "Respond to Webhook" retornando `{ "reply": "..." }`. Lembre de configurar CORS no nó Webhook.

## Passo 3 — Configurar o app

Edite as 4 linhas no topo do `<script>` do `index.html`:

```js
const SUPABASE_URL = 'COLE_AQUI_A_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'COLE_AQUI_A_SUPABASE_ANON_KEY';
const N8N_WEBHOOK_URL = 'COLE_AQUI_A_URL_DO_WEBHOOK_N8N';
const N8N_WEBHOOK_SECRET = 'COLE_AQUI_UM_SEGREDO_QUALQUER';
```

## Passo 4 — GitHub + Vercel

Mesmo fluxo de sempre: sobe `index.html`, `schema.sql`, `README.md` no repositório, importa na Vercel, deploy.

## Estrutura dos dados

- `clients`: nome, nicho
- `periods`: um por cliente — período + dados comerciais (qualificados, reuniões, propostas, vendas, receita)
- `marketing_entries`: várias por período — uma linha por mídia (plataforma, investimento, impressões, cliques, leads)

Todas as métricas derivadas (CPL, CAC, ROAS, CTR, taxas de funil) são calculadas no navegador a partir dessas três tabelas — não ficam guardadas, sempre refletem os dados mais atuais. Protegido por RLS, como os outros apps.
