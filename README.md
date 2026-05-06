# tracing — material de aula

> **Distributed tracing na prática** — duas implementações da mesma aula em linguagens diferentes, mostrando que o conceito de paralelizar I/O é independente de stack.

**Autor:** Rafael Friederick — [Unnamed-Lab](https://unnamed-lab.com)

---

## O que é este monorepo

Este é o repositório-pai. As implementações de fato vivem em **submódulos**, e a infraestrutura compartilhada (Postgres, Tempo, Grafana, Prometheus) vive na raiz, em `docker/`.

| Componente        | Tipo                                                    | Repositório                                    |
| ----------------- | ------------------------------------------------------- | ---------------------------------------------- |
| [`go/`](./go)     | Submódulo (Go 1.26 + Gin + pgx + OTEL)                  | <https://github.com/rafaelmfried/tracing-go>   |
| [`node/`](./node) | Submódulo (Node 24 + Fastify + pg + OTEL)               | <https://github.com/rafaelmfried/tracing-node> |
| `docker/`         | Infra compartilhada — orquestrada pelo Makefile da raiz | (este repo)                                    |

Os dois submódulos implementam **a mesma demo** com primitivas diferentes:

| Conceito   | Go                                                | Node                   |
| ---------- | ------------------------------------------------- | ---------------------- |
| Sequencial | `for { runQuery() }`                              | `for...of` com `await` |
| Paralelo   | `errgroup.WithContext` + `g.Go(...)` + `g.Wait()` | `Promise.all([...])`   |

| Rota            | Comportamento                | Esperado      |
| --------------- | ---------------------------- | ------------- |
| `GET /sync`     | 3 queries lentas em série    | ≈ N × `SLEEP` |
| `GET /parallel` | 3 queries lentas em paralelo | ≈ 1 × `SLEEP` |

---

## Clonando

**A forma certa** (com submódulos):

```bash
git clone --recurse-submodules https://github.com/rafaelmfried/tracing.git
cd tracing
make init       # cria .env, garante submódulos sincronizados
make up all     # sobe go + node + infra + observabilidade
```

**Já clonou sem `--recurse-submodules`?** Duas saídas:

```bash
make init       # tenta puxar os submodules sem refazer o checkout
# OU, do zero:
make reclone    # apaga este diretório e re-clona corretamente
```

`make reclone` é interativo — pede confirmação, avisa se há trabalho não pushado, e re-clona no mesmo lugar.

---

## Comandos principais

Tudo passa pelo `Makefile` da raiz, que orquestra o `docker/compose.yaml` consolidado via **profiles**:

```bash
make help                 # cheat sheet completa

# Subir/derrubar subsets coesos (use 'all' para tudo):
make up go                # api-go + postgres + tempo
make up node              # api-node + postgres + tempo
make up infra             # postgres
make up obs               # prometheus + tempo + grafana
make up all               # tudo

make down go              # mesma sintaxe para derrubar
make restart node         # idem
make logs all             # tail combinado
make clean                # down + apaga volumes (Postgres e Grafana zerados)

# Testes (delegam para os submódulos):
make test                 # go + node
make test-go
make test-node
```

Endereços (defaults, ajustáveis em `.env`):

- API Go: <http://localhost:8090> · Swagger: <http://localhost:8090/swagger/index.html>
- API Node: <http://localhost:8091> · Swagger: <http://localhost:8091/swagger>
- Grafana (anônimo Admin): <http://localhost:3000> — abre direto no dashboard "Tracing — Home"
- Tempo (API): <http://localhost:3200>
- Prometheus: <http://localhost:9090>

---

## Estrutura

```
tracing/                           ← este repo (monorepo / pai)
├── README.md                      ← visão geral da aula
├── Makefile                       ← orquestrador (use: make up [go|node|infra|obs|all])
├── .env.example
├── .gitmodules
├── docker/                        ← infra compartilhada
│   ├── compose.yaml               ← go + node + postgres + tempo + grafana + prometheus
│   ├── Dockerfile.{tempo,prometheus,grafana}
│   ├── tempo.yaml
│   ├── prometheus.yaml
│   └── grafana/{provisioning, dashboards/home.json}
├── scripts/
│   ├── make-help.sh               ← gera tela de ajuda colorida
│   └── reclone.sh                 ← apaga e re-clona com submodules
├── go/                            ← submódulo Go
│   ├── cmd/api/, internal/, docker/, Makefile, ...
│   └── README.md                  ← roteiro da aula em Go
└── node/                          ← submódulo Node
    ├── src/, tests/, docker/, Makefile, ...
    └── README.md                  ← roteiro paralelo em Node
```

---

## Roteiro da aula

1. **Conceitos** (slides separados): trace, span, context propagation; OpenTelemetry; Tempo + Grafana.
2. **Setup**: `make init && make up all` — leva ~30s na primeira vez (build das imagens).
3. **Demo Go** — bater `/sync` e `/parallel` em :8090, ver os 4 painéis no Grafana → Home.
4. **Demo Node** — repetir em :8091; mostrar que os mesmos painéis no Grafana ganham traces do `tracing-node` lado a lado.
5. **Discussão final** — concorrência é uma propriedade da modelagem. As primitivas mudam (goroutines/errgroup ↔ Promise.all), o trace continua o mesmo.

---

## Trabalhando com o monorepo (devs)

**Editando um submódulo:**

```bash
cd go            # entra no submódulo
git checkout main && git pull
# ... edita, testa ...
git add -A && git commit -m "..."
git push origin main

cd ..            # volta pro pai
git add go       # registra o novo SHA do submódulo
git commit -m "chore: bump go submodule"
git push
```

**Atualizando submódulos para o último HEAD remoto:**

```bash
git submodule update --remote --merge
git add go node
git commit -m "chore: bump submodules"
```

---

## Licença

MIT — Rafael Friederick / Unnamed-Lab. Material livre para uso educacional, com atribuição.
