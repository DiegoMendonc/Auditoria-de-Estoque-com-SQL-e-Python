PRAGMA foreign_keys = ON;
BEGIN;

CREATE TABLE materiais (
    id INTEGER PRIMARY KEY,
    sku TEXT NOT NULL UNIQUE,
    descricao TEXT NOT NULL,
    categoria TEXT NOT NULL,
    unidade TEXT NOT NULL,
    custo_referencia_centavos INTEGER NOT NULL CHECK (custo_referencia_centavos > 0)
);

CREATE TABLE depositos (
    id INTEGER PRIMARY KEY,
    nome TEXT NOT NULL
);

CREATE TABLE saldos_iniciais (
    material_id INTEGER NOT NULL REFERENCES materiais(id),
    deposito_id INTEGER NOT NULL REFERENCES depositos(id),
    data_base TEXT NOT NULL,
    quantidade INTEGER NOT NULL CHECK (quantidade >= 0),
    PRIMARY KEY (material_id, deposito_id)
);

CREATE TABLE movimentacoes (
    id INTEGER PRIMARY KEY,
    documento TEXT NOT NULL UNIQUE,
    material_id INTEGER NOT NULL,
    deposito_id INTEGER NOT NULL,
    tipo TEXT NOT NULL CHECK (tipo IN ('ENTRADA', 'SAIDA')),
    quantidade INTEGER NOT NULL CHECK (quantidade > 0),
    ocorrido_em TEXT NOT NULL,
    registrado_em TEXT NOT NULL CHECK (registrado_em >= ocorrido_em),
    FOREIGN KEY (material_id, deposito_id) REFERENCES saldos_iniciais(material_id, deposito_id)
);

CREATE INDEX idx_movimentacoes_item_corte
    ON movimentacoes (material_id, deposito_id, registrado_em);

INSERT INTO depositos VALUES (1, 'Depósito Norte'), (2, 'Depósito Sul');

WITH RECURSIVE serie(n) AS (
    VALUES (1)
    UNION ALL SELECT n + 1 FROM serie WHERE n < 240
)
INSERT INTO materiais
SELECT n, printf('MAT-%04d', n), printf('Material %03d', n),
       CASE n % 4 WHEN 0 THEN 'Embalagem' WHEN 1 THEN 'Manutenção'
                  WHEN 2 THEN 'Insumo' ELSE 'Consumo' END,
       'UN', 150 + (n * 193) % 18000
FROM serie;

INSERT INTO saldos_iniciais
SELECT m.id, d.id, '2026-09-01 00:00:00',
       CASE WHEN m.id = 1 AND d.id = 1 THEN 0 ELSE 300 + (m.id * 31 + d.id * 19) % 700 END
FROM materiais m CROSS JOIN depositos d;

-- 36 mil lançamentos. Parte dos eventos ocorreu antes do corte, com registro posterior.
WITH RECURSIVE serie(n) AS (
    VALUES (1)
    UNION ALL SELECT n + 1 FROM serie WHERE n < 36000
),
eventos AS (
    SELECT n, (n - 1) % 240 + 1 AS material_id,
           ((n - 1) / 240) % 2 + 1 AS deposito_id,
           datetime('2026-09-01 00:00:00', printf('+%d hours', (n * 137) % 792)) AS ocorrido_em
    FROM serie
)
INSERT INTO movimentacoes
SELECT n, printf('MOV-%06d', n), material_id, deposito_id,
       CASE WHEN (n / 480 + material_id) % 4 < 2 THEN 'ENTRADA' ELSE 'SAIDA' END,
       1 + (n * 17 + n / 480) % 8,
       ocorrido_em,
       datetime(ocorrido_em, CASE WHEN n % 31 = 0 THEN '+48 hours' ELSE '+1 hour' END)
FROM eventos
WHERE material_id <> 1 OR deposito_id <> 1;

-- Três lançamentos de fronteira no mesmo item, incluindo um registro no instante do corte.
INSERT INTO movimentacoes VALUES
    (36001, 'MOV-036001', 2, 1, 'ENTRADA', 7, '2026-09-30 17:59:00', '2026-09-30 18:00:00'),
    (36002, 'MOV-036002', 2, 1, 'ENTRADA', 9, '2026-09-30 17:59:00', '2026-09-30 18:01:00'),
    (36003, 'MOV-036003', 2, 1, 'SAIDA', 4, '2026-09-30 18:01:00', '2026-09-30 18:02:00');

COMMIT;
