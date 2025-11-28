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
Programa--------: MFIS008
Autor-----------: Igor Melgaco
Data da Criacao-: 03/05/2022
Descrição-------: CHAMADO 39972 - Rotina para limpeza de códigos de ajuste com valor zerado da Tabela CDA.
Parametros------: NENHUM
Retorno---------: NENHUM
===============================================================================================================================

Esta rotina é uma medida paliativa para atender a usuária até que o departamento 
fiscal de Corumbaiba, consiga analisar e separar quais são as operações isentas que 
não geram valor, e assim crie uma TES separada sem o código de ajuste amarrado.

*/
User Function MFIS008()

   FWMsgRun( , {|| MFIS008A() } ,'Processando...' , 'Aguarde!' )

Return

/*
===============================================================================================================================
Programa----------: MFIS008A
Autor-------------: Igor Melgaco
Data da Criacao---: 03/05/2022
Descrição---------: Executa a query e o processamento da exclusão
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MFIS008A()

Local _cAlias   := GetNextAlias()
Local cCodAjus := U_ITGETMV("ITCODLAN",'GO40000029') 
Local i        := 0
Local aLog     := {}
Local aCab     := {}
Local _cTitulo := "Registros a deletar"

aCab := {"","Filial","Especie","Numero","Serie","Cliente/Fornecedor","Loja","Valor","Cod. Lanc.","Recno"}


BeginSql alias _cAlias
   SELECT CDA_FILIAL,CDA_ESPECI,CDA_NUMERO,CDA_SERIE,CDA_CLIFOR,CDA_LOJA, CDA_VALOR,CDA_CODLAN,R_E_C_N_O_
   FROM %Table:CDA%
   WHERE CDA_VALOR = 0
   AND CDA_CODLAN = %exp:cCodAjus%
   AND D_E_L_E_T_ = ' ' "
   AND CDA_FILIAL = %xFilial:CDA%
EndSql

While (_cAlias)->(!Eof())

   aAdd(aLog,{.F.,;
   (_cAlias)->CDA_FILIAL,;
   (_cAlias)->CDA_ESPECI,;
   (_cAlias)->CDA_NUMERO,;
   (_cAlias)->CDA_SERIE,;
   (_cAlias)->CDA_CLIFOR,;
   (_cAlias)->CDA_LOJA,;
   (_cAlias)->CDA_VALOR,;
   (_cAlias)->CDA_CODLAN,;
   (_cAlias)->R_E_C_N_O_})
   
   (_cAlias)->(DBSkip())

EndDo

(_cAlias)->(DBCloseArea())

If Len(aLog) > 0
   _lRet := U_ITListBox(_cTitulo,aCab,aLog   , .T.    , 2    ,_cTitulo /*_cMsgTop*/,          ,        ,         ,     ,        ,          ,       ,         ,          , /*bCondMarca*/)

   If _lRet

      For i := 1 to Len(aLog)
         If aLog[i,1]
            DBSelectArea("CDA")
            CDA->(DBGoTo(aLog[i,10]))
            CDA->(RecLock("CDA", .F.))
            DbDelete()
            MSUnLock()

         EndIf
      Next

      U_ITMsg("Processamento concluído!","Atenção",,2)

   EndIf
Else
   U_ITMsg("Não encontrado registros para deleção!","Atenção",,2)
EndIf

Return
