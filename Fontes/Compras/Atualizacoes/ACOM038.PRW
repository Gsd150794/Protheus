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
Programa----------: ACOM038
Autor-------------: Julio de Paula Paz
Data da Criacao---: 19/11/2019
Descrição---------: Rotina de manutenção do Cadastro de TES X GRUPO X MARGEM.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM038()

Local _cTitulo := "Cadastro de TES X GRUPO X MARGEM"                        

Begin Sequence                                
   AxCadastro("ZM2",_cTitulo, ,"U_ACOM038V('COK')")

End Sequence

Return             

/*
===============================================================================================================================
Programa----------: ACOM038V
Autor-------------: Julio de Paula Paz
Data da Criacao---: 19/11/2019
Descrição---------: Valida a inclusão e alteração de dados na manutenção do Cadastro de TES X GRUPO X MARGEM.
Parametros--------: Nenhum
Retorno-----------: _lRet = .T. / .F.
===============================================================================================================================
*/
User Function ACOM038V(_cChamada)

Local _lRet    := .T.
Local _nRegAtu := ZM2->(Recno())

Default _cChamada := ""

Begin Sequence                       
   ZM2->(DBSetOrder(1))
   
   If Inclui 
      If ZM2->(DBSeek(xFilial("ZM2") + M->ZM2_TES + M->ZM2_GRUPO))    
         U_ITMsg("Para a filial " + xFilial("ZM2") + ", já existe cadastrado a TES " + M->ZM2_TES + " e o grupo " + M->ZM2_GRUPO + "." ,"Atenção" , "Inclua uma relação Filial x TES x Grupo que não exista." , 1) 
         _lRet := .F.
      EndIf
   EndIf
   
End Sequence

If _nRegAtu > 0
   ZM2->(DBGoTo(_nRegAtu))
EndIf

Return _lRet
