# tracing — material de aula

> **Distributed tracing na prática** — duas implementações da mesma aula em linguagens diferentes, mostrando que o conceito de paralelizar I/O é independente de stack.

**Autor:** Rafael Friederick — [Unnamed-Lab](https://unnamed-lab.com)

---

## O que é este monorepo

Este é o repositório-pai. As implementações de fato vivem em **submódulos**:

| Submódulo | Stack | Repositório |
| --------- | ----- | ----------- |
| [`go/`](./go) | Go 1.26 + Gin + pgx + OpenTelemetry | <https://github.com/rafaelmfried/tracing-go> |
| [`node/`](./node) | Node 24 + TypeScript (em construção) | <https://github.com/rafaelmfried/tracing-node> |

Os dois implementam **a mesma demo**:

| Rota | Comportamento | Esperado |
| ---- | ------------- | -------- |
| `GET /sync` | Roda 3 queries lentas sequencialmente | ≈ N × `SLEEP` |
| `GET /parallel` | Roda 3 queries lentas em paralelo | ≈ 1 × `SLEEP` |

A diferença está em **como cada linguagem expressa concorrência**:

| Conceito | Go | Node |
| -------- | -- | ---- |
| Sequencial | `for { runQuery() }` | `for await (const q of queries)` |
| Paralelo | `errgroup.WithContext` + `g.Go(...)` + `g.Wait()` | `Promise.all([...])` |

A intuição é a mesma. O **trace** no Tempo mostra o waterfall idêntico — porque o que muda é só a primitiva, não o resultado observável.

---

## Como clonar

Sempre clone com `--recurse-submodules`:

```bash
git clone --recurse-submodules https://github.com/rafaelmfried/tracing.git
cd tracing
```

Já clonou sem? Atualize:

```bash
git submodule update --init --recursive
```

Para puxar a última versão de cada submódulo:

```bash
git submodule update --remote --merge
```

---

## Estrutura

```
tracing/                          ← este repo (monorepo / pai)
├── README.md                     ← visão geral da aula
├── .gitmodules
├── go/                           ← submódulo Go (tracing-go)
│   ├── cmd/api/
│   ├── internal/{app,infra,...}
│   ├── docker/{compose.yaml, ...}
│   └── README.md                 ← roteiro da aula em Go
└── node/                         ← submódulo Node (tracing-node)
    └── README.md                 ← roteiro paralelo em Node (em construção)
```

---

## Roteiro da aula (visão geral)

1. **Conceitos** (slides separados): o que é trace, span, context propagation; OpenTelemetry; Tempo + Grafana.
2. **Demo Go** — entrar em `go/`, seguir o README:
   - Subir `make up` (api + Postgres + Tempo + Grafana provisionado).
   - Bater `/sync` e `/parallel`, ver o `total_ms` na resposta.
   - Abrir o **Tracing — Home** dashboard no Grafana — comparar waterfall.
   - Discutir: pool de conexões, `errgroup`, dependência entre queries.
3. **Demo Node** — entrar em `node/`, mesma sequência. Mostrar como `Promise.all` substitui `errgroup`.
4. **Discussão final** — concorrência é uma propriedade da modelagem, não da linguagem.

---

## Trabalhando com o monorepo

**Editando um submódulo:**

```bash
cd go            # entra no submódulo
git checkout main
# ... edita, testa ...
git add -A && git commit -m "..."
git push origin main

cd ..            # volta pro pai
git add go       # registra o novo SHA do submódulo
git commit -m "chore: bump go submodule"
git push
```

**Rodando os dois ao mesmo tempo (planejado):** um `compose.yaml` no nível do monorepo que sobe ambas as APIs (portas diferentes) compartilhando o mesmo Tempo, para demonstrar lado a lado.

---

## Licença

MIT — Rafael Friederick / Unnamed-Lab. Material livre para uso educacional, com atribuição.
