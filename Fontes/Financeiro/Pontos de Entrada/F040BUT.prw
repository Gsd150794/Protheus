/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |11/01/2019| Chamado 27267. Novo botão "Ocorrencia de frete"
Jerry         |29/09/2021| Chamado 37679. Adicionar campos novos da Ocorrência de Frete.
Jerry         |05/08/2022| Chamado 40929. Adicionar o campo Data Inicial.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: F040BUT
Autor-----------: Alexandre Villar
Data da Criacao-: 14/01/2016
Descrição-------: P.E. para inclusão de botões na tela de manutenção dos títulos a receber no Financeiro
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function F040BUT()

	Local _aRotAux := {}

	aAdd( _aRotAux , { "Histórico" , {|| U_AFIN005() } , "Histórico..." , "Histórico" } )

	aAdd( _aRotAux , { "FRETE", {|| U_FA4OcoFrete() }, "Ocorrencia de frete"})


Return( _aRotAux )

User Function FA4OcoFrete()
	Local _aCols  :={},C
	Local _aHeader:={}
	Local _aSizes :={         20,         20,          40,         35,          45,          45,         40,          40,          40,          40,          40,          40,          40,         40,         20 ,        20}
	Local _aCampos:={'ZF5_DOCOC','ZF5_SEROC',"ZF5_STATUS","ZF5_DTINI","ZF5_DTOCOR","ZF5_MOTIVO","ZF5_MOTCUS","ZF5_CUSTO","ZF5_CUSTOC","ZF5_CUSTOI","ZF5_CUSTOR","ZF5_CUSTOC","ZF5_CUSTOT","ZF5_CUSTER","ZF5_DTFIN","ZF5_MERENT","ZF5_SITENT"}
	Local _cEntr  := ""

 
	If Empty(M->E1_NUM)
		U_ITMsg("Digite o No. do Titulo",'Atenção!',,1)
		Return .F.
	EndIf
 
	ZF5->(DBSetOrder(1))
	If ZF5->(DBSeek(xFilial("SE1")+M->E1_NUM))

		For C := 1 TO Len(_aCampos)
			aAdd(_aHeader, AVSX3(_aCampos[C],5) )
		Next

		While ZF5->(!Eof()) .And. xFilial("SE1")+M->E1_NUM == ZF5->ZF5_FILIAL+ZF5->ZF5_DOCOC
			aAdd(_aCols, ARRAY(Len(_aCampos)) )
			For C := 1 TO Len(_aCampos)
				If !_aCampos[C] $ "ZF5_STATUS"
					_xValor:=ZF5->( FIELDGET(FIELDPOS( _aCampos[C] )) )
					If ValType(_xValor) = "N"
						_aCols[Len(_aCols),C]:=TransForm(_xValor, PesqPict('ZF5', _aCampos[C]) )
					ElseIf ValType(_xValor) = "D"
						_aCols[Len(_aCols),C]:=DToC(_xValor)
					Else
						_aCols[Len(_aCols),C]:=AllTrim(_xValor)
					EndIf
               //inicio
               If AllTrim(_aCampos[C]) == "ZF5_SITENT"
		   	      If ZF5->ZF5_SITENT == "P"
			   	      _cEntr := "PARCIAL"
				      ElseIf ZF5->ZF5_SITENT == "I"
						   _cEntr := "INTEGRAL"
   					Else
						   _cEntr := " "
   					EndIf
	   				_aCols[Len(_aCols),C]:= _cEntr
               EndIf
               //fim
				ElseIf AllTrim(_aCampos[C]) == "ZF5_STATUS"
					_aCols[Len(_aCols),C]:=AllTrim(Posicione("ZFD",1,xFilial("ZFD")+ZF5->ZF5_STATUS,"ZFD_DESCRI"))
				EndIf
			Next
			ZF5->(DBSkip())
		EndDo
	Else
		U_ITMsg("Não existem ocorrencias de frete para o Numero: "+M->E1_NUM,'Atenção!',,1)
	EndIf

	If Len(_aCols) > 0

		_cTitAux:="OCORENCIAS DE FRETE"
//   ITLISTBOX( _cTitAux,_aHeader , _aCols , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons
		U_ITLISTBOX( _cTitAux,_aHeader , _aCols, .T.       , 1      ,          ,          ,_aSizes , )
	EndIf

Return
