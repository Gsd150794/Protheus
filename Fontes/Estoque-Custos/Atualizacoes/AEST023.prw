/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |10/09/2024| Chamado 48465. Removendo warning de compilação.
Julio Paz     |06/11/2024| Chamado 48857. Criar uma Opção no Cadastro de Subgrupos de Produtos para o Usuário Alterar Apenas o 
              |          | Campo Código da Familia do subgrupo
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AEST023
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 20/04/2010
Descrição---------: Rotina para realizar as operacoes de inclusao, alteracao e exclusao dos dados do Sub Grupo
					As informacoes desse cadastro sera utilizado pelo campo SB1->B1_I_SUBGR
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST023

Private cAlias		:= "ZB9"
Private cCadastro	:= "Cadastro de sub Grupo"
Private aRotina		:= {}                

aAdd(aRotina,{"Pesquisar"	,"AxPesqui",0,1})
aAdd(aRotina,{"Visualizar"	,"AxVisual",0,2})
aAdd(aRotina,{"Incluir"		,"AxInclui",0,3})
aAdd(aRotina,{"Alterar"		,"U_ValZB9",0,4})
aAdd(aRotina,{"Excluir"		,"U_ValZB9",0,5})
aAdd(aRotina,{"Alterar Familia","U_AEST023A()",0,4})
	
mBrowse(6,1,22,75,cAlias)

Return

/*
===============================================================================================================================
Programa----------: ValZB9
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 20/04/2010
Descrição---------: Programa de Validacao da Alteracao e Exclusao, chamado pelo programa AEST023()
					Valida a alteracao e exclusao dos dados na tabela ZB9010, caso o codigo a ser excluido ja tenha amarracao na
					tabela SB1010 o programa nao permite a alteracao ou exclusao.
Parametros--------: cAlias,nReg,nOpc
Retorno-----------: Retorno Logico (.T. ou .F.) para exclusao ou alteracao
===============================================================================================================================
*/
User Function ValZB9(cAlias,nReg,nOpc)

Local _aArea 	:= FWGetArea()
Local _lRet		:= .F.
Local _cAlias	:= GetNextAlias()

BeginSql alias _cAlias
	SELECT COUNT(1) QTD FROM %Table:SB1% 
	WHERE D_E_L_E_T_ = ' ' AND B1_I_SUBGR = %exp:ZB9->ZB9_SUBGRU%
EndSql

If (_cAlias)->QTD > 0
	_lRet	:= .F.
   U_ITMsg("Não será possível realizar a alteração ou exclusao de sub Grupos que estejam amarrados ao cadastro de algum produto. "+;
           "Favor excluir o cadastro de produtos que possui o Sub Grupo que deseja realizar a exclusão.","Atenção",,1)
EndIf

(_cAlias)->(DBCloseArea())

If _lRet .And. nOpc == 4
	AxAltera(cAlias,nReg,nOpc)
ElseIf _lRet .And. nOpc == 5 
	AxDeleta(cAlias,nReg,nOpc)
EndIf
FWRestArea(_aArea)

Return _lRet 

/*
===============================================================================================================================
Programa--------: AEST023A()
Autor-----------: Julio de Paula Paz
Data da Criacao-: 25/10/2024
Descrição-------: Permite alterar apenas o campo código da Familia do subgrupo.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AEST023A()
Local _cTitulo
Local _bOk, _bCancel 
Local _oDlgF
Local _lRet := .T.
//Local _nTamPedido := TamSX3("C5_NUM")[1]  
Local _cCodFamPr := ZB9->ZB9_CODFAM
Local _cDescFam  := Posicione("ZB3",1,xFilial("ZB3")+ZB9->ZB9_CODFAM,"ZB3_DESFAM")
Local _cDescFNov := ""  
Local _cTextPerg

Begin Sequence
   //================================================================================
   // Tela de Aprovação de Pedido de Vendas
   //================================================================================      
   _cTitulo := "Alteração do Código da Familia do Subgrupo"
   _bOk := {|| If(U_AEST023V(_cCodFamPr),(_lRet := .T., _oDlgF:End()),)}
   _bCancel := {|| _lRet := .F., _oDlgF:End()}
   
   Define MsDialog _oDlgF Title _cTitulo From 9,0 To 20,90 Of oMainWnd 
      
      @ 40,20 Say "Codigo Familia Subgrupo: " Of _oDlgF Pixel
      @ 37,80 MsGet _cCodFamPr F3 "ZB3" Size 10, 12 Of _oDlgF Valid(U_AEST023V(_cCodFamPr)) Pixel

   Activate MsDialog _oDlgF On Init EnchoiceBar(_oDlgF,_bOk,_bCancel) CENTERED 

   _cDescFNov := Posicione("ZB3",1,xFilial("ZB3")+_cCodFamPr,"ZB3_DESFAM")

   _cTextPerg := "Confirma a alteração do código '" + AllTrim(_cDescFam) + "' da família do subgrupo '" + AllTrim(ZB9->ZB9_DESSUB) + "' para o código '" + AllTrim(_cDescFNov) + "' ?"

   If _lRet .And. U_ITMsg(_cTextPerg,"Atenção" , , ,2, 2) 
	   ZB9->(RecLock("ZB9",.F.))
	   ZB9->ZB9_CODFAM := _cCodFamPr
      ZB9->(MSUnLock()) 

      U_ITMsg("Código da familia do subgrupo alterado com sucesso.","Atenção",,2)
   EndIf 

   If ! _lRet	
      U_ITMsg("Alteração do Código da familia do subgrupo cancelada.","Atenção",,1)
   EndIf

End Sequence

Return

/*
===============================================================================================================================
Programa--------: AEST023V()
Autor-----------: Julio de Paula Paz
Data da Criacao-: 25/10/2024
Descrição-------: Valida a tela de alteração do código da familia do subgrupo.
Parametros------: _cConteudo = Conteúdo informado na Tela
Retorno---------: _lRet = .T. = Validação OK
                          .F. = Validação inválida
===============================================================================================================================
*/
User Function AEST023V(_cConteudo)
Local _lRet := .T.

Begin Sequence

   If Empty(_cConteudo)
      U_ITMsg("Código da familia do subgrupo não preenchido. O preenchimento deste campo é obrigatório.","Atenção",,1)
	  _lRet := .F.
	  Break
   EndIf 

   ZB3->(DBSetOrder(1))    
   If ! ZB3->(MsSeek(xFilial("ZB3")+_cConteudo))
      U_ITMsg("Código da familia do subgrupo informado, não existe no cadastro de familias de subgrupos.","Atenção",,1)
	  _lRet := .F.
	  Break
   EndIf                                                     

End Sequence 

Return _lRet 
