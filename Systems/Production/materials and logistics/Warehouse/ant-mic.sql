SELECT 
    ds_produto,
    ds_unidade,
    ROUND(SUM(qt_consumo)) AS qt_consumo,
    ROUND(SUM(qt_presc)) AS qt_presc,
    ROUND((SUM(qt_consumo) * 100) / NULLIF(SUM(qt_presc), 0)) AS qt_total
FROM (
    SELECT 
        ds_produto,
        ds_unidade,
        SUM(qt_consumo) AS qt_consumo,
        f.cd_produto,
        a.cd_atendimento,
        0 AS qt_presc    
    FROM (
        SELECT 
            produto.ds_produto AS ds_produto,
            verif_ds_unid_prod(produto.cd_produto, 'G') AS ds_unidade,
            ROUND(SUM(resultado.qt_consumo), 2) AS qt_consumo,
            produto.cd_produto,
            resultado.cd_atendimento
        FROM (
            -- Primeiro SELECT
            SELECT 
                produto.cd_produto,
                TRUNC(
                    SUM(
                        DECODE(mvto_estoque.tp_mvto_estoque, 'D', -1, 'C', -1, 'N', -1, 1) * 
                        (itmvto_estoque.qt_movimentacao * uni_pro.vl_fator)
                    ), 4
                ) / verif_vl_fator_prod(produto.cd_produto) AS qt_consumo,
                mvto_estoque.cd_atendimento,
                0 AS qtd_presc
            FROM dbamv.mvto_estoque,
                 dbamv.itmvto_estoque,
                 dbamv.produto,
                 dbamv.sub_clas,
                 dbamv.estoque,
                 dbamv.uni_pro,
                 dbamv.classe,
                 dbamv.especie
            WHERE estoque.cd_multi_empresa = 1
              AND produto.tp_ativo = 'S'
              AND mvto_estoque.cd_mvto_estoque = itmvto_estoque.cd_mvto_estoque
              AND itmvto_estoque.cd_produto = produto.cd_produto
              AND produto.cd_especie = especie.cd_especie
              AND produto.cd_classe = classe.cd_classe
              AND especie.cd_especie = classe.cd_especie
              AND especie.cd_especie = sub_clas.cd_especie
              AND classe.cd_classe = sub_clas.cd_classe
              AND produto.cd_sub_cla = sub_clas.cd_sub_cla
              AND itmvto_estoque.cd_uni_pro = uni_pro.cd_uni_pro
              AND mvto_estoque.cd_estoque = estoque.cd_estoque
              AND produto.sn_mestre <> 'S'
              AND mvto_estoque.tp_mvto_estoque IN ('D', 'C', 'S', 'P', DECODE(estoque.tp_estoque, 'D', 'T', '#'))
              AND produto.cd_especie = 1
              AND produto.cd_classe = 5
              AND produto.cd_produto LIKE '%'
              AND mvto_estoque.dt_mvto_estoque BETWEEN TO_DATE('01/10/2024', 'dd/mm/yyyy') AND TO_DATE('09/10/2024', 'dd/mm/yyyy')
              AND estoque.cd_estoque IN (3)
            GROUP BY produto.cd_produto, mvto_estoque.cd_atendimento
            
            UNION ALL
            
            -- Segundo SELECT
            SELECT 
                produto.cd_produto,
                TRUNC(
                    SUM(
                        DECODE(mvto_estoque.tp_mvto_estoque, 'T', 1, 0) * 
                        (itmvto_estoque.qt_movimentacao * uni_pro.vl_fator) * (-1)
                    ), 4
                ) / verif_vl_fator_prod(produto.cd_produto) AS qt_consumo,
                mvto_estoque.cd_atendimento,
                0 AS qtd_presc
            FROM dbamv.mvto_estoque,
                 dbamv.itmvto_estoque,
                 dbamv.produto,
                 dbamv.sub_clas,
                 dbamv.estoque,
                 dbamv.uni_pro,
                 dbamv.classe,
                 dbamv.especie
            WHERE estoque.cd_multi_empresa = 1
              AND produto.tp_ativo = 'S'
              AND mvto_estoque.cd_mvto_estoque = itmvto_estoque.cd_mvto_estoque
              AND itmvto_estoque.cd_produto = produto.cd_produto
              AND produto.cd_especie = especie.cd_especie
              AND produto.cd_classe = classe.cd_classe
              AND especie.cd_especie = classe.cd_especie
              AND especie.cd_especie = sub_clas.cd_especie
              AND classe.cd_classe = sub_clas.cd_classe
              AND produto.cd_sub_cla = sub_clas.cd_sub_cla
              AND itmvto_estoque.cd_uni_pro = uni_pro.cd_uni_pro
              AND produto.sn_mestre <> 'S'
              AND mvto_estoque.cd_estoque_destino = estoque.cd_estoque
              AND mvto_estoque.tp_mvto_estoque IN (DECODE(estoque.tp_estoque, 'D', 'T', '#'))
              AND produto.cd_especie = 1
              AND produto.cd_classe = 5
              AND produto.cd_produto LIKE '%'
              AND mvto_estoque.dt_mvto_estoque BETWEEN TO_DATE('01/10/2024', 'dd/mm/yyyy') AND TO_DATE('09/10/2024', 'dd/mm/yyyy')
              AND estoque.cd_estoque IN (3)
            GROUP BY produto.cd_produto, mvto_estoque.cd_atendimento
        ) resultado,
        dbamv.produto
        WHERE resultado.cd_produto = produto.cd_produto
          AND EXISTS (
              SELECT empresa_produto.cd_produto
              FROM dbamv.empresa_produto
              WHERE cd_multi_empresa = 1
                AND empresa_produto.cd_produto = produto.cd_produto
          )
          AND qt_consumo > 0
        GROUP BY produto.cd_produto, produto.ds_produto, verif_ds_unid_prod(produto.cd_produto), cd_atendimento
    ) f
    INNER JOIN dbamv.atendime a ON f.cd_atendimento = a.cd_atendimento
    INNER JOIN dbamv.paciente p ON a.cd_paciente = p.cd_paciente
    GROUP BY ds_produto, ds_unidade, f.cd_produto, a.cd_atendimento, p.cd_paciente

    UNION ALL

    SELECT 
        p.ds_produto,
        verif_ds_unid_prod(p.cd_produto, 'G') AS ds_unidade,
        0 AS qt_consumo,
        p.cd_produto,
        cd_atendimento,
        COUNT(*) AS qtd_presc
    FROM (
        SELECT 
            ssp.cd_pre_med,
            issp.cd_produto,
            ssp.cd_atendimento,
            ssp.cd_estoque,
            ssp.cd_setor
        FROM dbamv.solsai_pro ssp
        INNER JOIN dbamv.itsolsai_pro issp ON ssp.cd_solsai_pro = issp.cd_solsai_pro
        INNER JOIN dbamv.pre_med pm ON ssp.cd_pre_med = pm.cd_pre_med
        INNER JOIN dbamv.itpre_med ipm ON pm.cd_pre_med = ipm.cd_pre_med AND issp.cd_produto = ipm.cd_produto
        WHERE ssp.tp_situacao = 'S'
          AND ssp.tp_solsai_pro = 'P'
          AND ssp.cd_mot_dev IS NULL
          AND ssp.tp_origem_solicitacao = 'PRE'
          AND ssp.dt_solsai_pro BETWEEN TO_DATE('01/10/2024','dd/mm/yyyy') AND TO_DATE('09/10/2024','dd/mm/yyyy')
        GROUP BY issp.cd_produto, ssp.cd_atendimento, ssp.cd_pre_med, ssp.cd_estoque, ssp.cd_setor
    ) subf1
    INNER JOIN dbamv.produto p ON subf1.cd_produto = p.cd_produto
    WHERE cd_setor IN (25,58)
      AND cd_estoque IN (3)
    GROUP BY cd_atendimento, p.cd_produto, p.ds_produto
) f
GROUP BY ds_produto, ds_unidade, cd_produto
HAVING SUM(qt_consumo) > 0;
