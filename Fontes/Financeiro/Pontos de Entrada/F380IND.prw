/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: F380IND()
Autor-------------: Alex Wallauer 
Data da Criacao---: 08/08/2019
Descrição---------: PONTO DE ENTRA DO FinA380 PARA CRIAR INDICES NO TRB - CHAMADO 29611
Parametros--------: Nenhum
Retorno-----------: aIndex - Indices
===============================================================================================================================
*/
User Function F380IND()
Local aIndex:={}

aAdd(aIndex,{"A",{"E5_DATA"    },"Data Disponibilizacao (Italac)"})
aAdd(aIndex,{"B",{"E5_NUMCHEQ" },"Numero do Cheque"     })
//aAdd(aIndex,{"C",{"E5_VALOR"   },"Valor do Titulo"      }) JÁ TEM NO PADRÃO
aAdd(aIndex,{"D",{"E5_PREFIXO"  ,"E5_NUMERO"  ,"E5_PARCELA"},"Prefixo + Titulo + Parcela" })
aAdd(aIndex,{"E",{"E5_CLIFOR"   ,"E5_LOJA"   },"Cliente + Loja"                           })
aAdd(aIndex,{"F",{"E5_RECPAG"   ,"E5_NUMCHEQ"},"Ctas Receber / Ctas Pagar + Numero Cheque"})

Return aIndex
/*
User Function F380ATR()
Local aIndex:={}
Return .T.*/
