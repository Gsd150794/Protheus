/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |08/03/2022| Chamado 45904 - Fernando. Correção para salvar e retornar para a Matriula posicionada Atual.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: AGPE009
Autor-----------: Igor Melgaço
Data da Criacao-: 11/08/2023
Descrição-------: Rotina para Validação e gatilho do campo SRA->RA_I_MATSU. Chamado 44408.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AGPE009()

Local _nRenoSRA := SRA->(RECNO())
Local lRet := .T.

DBSelectArea("SRA")
DBSetOrder(1)
If !Empty(M->RA_I_MATSU) .And. DBSeek(xFilial("SRA")+M->RA_I_MATSU)
   M->RA_I_FUNSU := SRA->RA_NOME
   lRet := .T.
ElseIf !Empty(M->RA_I_MATSU)
   U_ITMsg("Código de Funcionário não pertencente ao cadastro.","Atenção!",,1)
   M->RA_I_FUNSU := Space(Len(SRA->RA_NOME))
   lRet := .F.
EndIf

If !SRA->(DBSeek(xFilial("SRA")+M->RA_MAT))
   SRA->(DBGoTo(_nRenoSRA))
EndIf

Return lRet
