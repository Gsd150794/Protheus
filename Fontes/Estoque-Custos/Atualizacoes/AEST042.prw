/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |10/10/2024| Chamado 48465. Retirada da função de conout
Lucas Borges  |23/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
Lucas Borges  |14/09/2025| Chamado 51799. Implementada função para validar ambiente de teste totvs.framework.environment.Type.get()
================================================================================================================================
*/

#Include 'FWMVCDEF.CH'
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AEST042
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 10/08/2016
Descrição---------: Central de Pallets Chep
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST042()

Local oBrowse		:= Nil

oBrowse := FWMBrowse():New()

oBrowse:SetAlias("ZE2")
oBrowse:SetDescription("Central de Pallets Chep")
oBrowse:Activate()

Return(Nil)

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 20/08/2015
Descrição---------: Rotina para montagem do modelo de dados para o processamento
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ModelDef()

Local oStruZE2	:= FWFormStruct(1,"ZE2")
Local oModel	:= Nil

oModel := MPFormModel():New('AEST042M',,{|oModel| AEST042TOK(oModel)})

oModel:AddFields('ZE2MASTER', , oStruZE2)

oModel:SetPrimaryKey( {'ZE2_FILIAL','ZE2_PRODUT','DToS(ZE2_DTCONT)'} )

Return(oModel)

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 20/08/2015
Descrição---------: Rotina para montar a View de Dados para exibição
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ViewDef()

Local oModel	:= FWLoadModel('AEST042')
Local oStruZE2	:= FWFormStruct(2,'ZE2')
Local oView		:= Nil

oView := FWFormView():New()

oView:SetModel(oModel)

oView:AddField('VIEW_ZE2',oStruZE2,'ZE2MASTER')

oView:CreateHorizontalBox('TELA', 100)

oView:SetOwnerView('VIEW_ZE2','TELA')

Return(oView)

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 20/08/2015
Descrição---------: Rotina para criação do menu da tela principal
Parametros--------: Nenhum
Retorno-----------: _aRotina - Array com as opções de menu
===============================================================================================================================
*/
Static Function MenuDef()

Local _aRotina := {}

ADD OPTION _aRotina Title 'Visualizar'	 Action 'VIEWDEF.AEST042'	OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Incluir'   	 Action 'VIEWDEF.AEST042'	OPERATION 3 ACCESS 0
ADD OPTION _aRotina Title 'Alterar'   	 Action 'U_AEST042Y()'		OPERATION 4 ACCESS 0
ADD OPTION _aRotina Title 'Med Consumo'  Action 'U_AEST042K()'		OPERATION 5 ACCESS 0
ADD OPTION _aRotina Title 'Visu. Logs'   Action 'U_AEST042Z()'		OPERATION 5 ACCESS 0
ADD OPTION _aRotina Title 'Envia E-mail' Action 'U_AESTS42()'		OPERATION 5 ACCESS 0

Return(_aRotina)

/*
===============================================================================================================================
Programa----------: AEST042VLD
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 20/08/2015
Descrição---------: Função criada para fazer a validação da digitação das datas.
Parametros--------: Nenhum
Retorno-----------: Lógico - .T. dados válidas, .F. dados inválidos
===============================================================================================================================
*/
User Function AEST042VLD()

Local _aArea	:= FWGetArea()
Local _lRet		:= .T.
Local _cCampo	:= ReadVar()
Local _nContSema

If 'ZE2_PALCPR' $ _cCampo .Or. 'ZE2_PALCEA' $ _cCampo .Or. 'ZE2_PALAVA' $ _cCampo .Or. 'ZE2_PALVAZ' $ _cCampo .Or. 'ZE2_PALSUJ' $ _cCampo
	//Faz a somatória dos Pallets
	M->ZE2_PALTOT := M->ZE2_PALCPR + M->ZE2_PALCEA + M->ZE2_PALAVA + M->ZE2_PALVAZ + M->ZE2_PALSUJ
EndIf

If 'ZE2_PALVAZ' $ _cCampo
	M->ZE2_AUTEST := M->ZE2_PALVAZ / M->ZE2_MEDCON
EndIf

If 'ZE2_PRODUT' $ _cCampo
	DBSelectArea("SB5")
	DBSetOrder(1)
	If DBSeek(xFilial("SB5") + M->ZE2_PRODUT)
		DBSelectArea("SB1")
		DBSetOrder(1)
		If DBSeek(xFilial("SB1") + M->ZE2_PRODUT)
			M->ZE2_DESCRI := AllTrim(SB1->B1_DESC)
		Else
			_aInfHlp := {}
			//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
			aAdd( _aInfHlp , { "O produto informado não foi encontrado."	, "                                     "	} )
			aAdd( _aInfHlp , { "Favor informar um produto válido.      "	, ""                                        } )

			U_ITCADHLP( _aInfHlp , "AEST04202" )

			_lRet := .F.
		EndIf
	Else
		_aInfHlp := {}
		//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
		aAdd( _aInfHlp , { "O produto informado não foi encontrado."	, "                                     "	} )
		aAdd( _aInfHlp , { "Favor informar um produto válido.      "	, ""                                        } )

		U_ITCADHLP( _aInfHlp , "AEST04202" )

		_lRet := .F.
	EndIf
EndIf

If "ZE2_LOCAL" $ _cCampo // Valida campo Armazém
   NNR->(DBSetOrder(1))
   If !Empty(M->ZE2_LOCAL) .And. ! NNR->(MsSeek(xFilial("NNR")+M->ZE2_LOCAL))

      Help( ,, 'Atenção',, 'O armazém informado não foi localizado no cadastro de armazéns.' , 1, 0 )
      _lRet := .F.
   EndIf 
EndIf

If "ZE2_DTCONT" $ _cCampo // Valida campo Data da Contagem
   If Empty(M->ZE2_DTCONT) 
      Help( ,, 'Atenção',, 'O preenchimento da data da contagem é obrigatório.' , 1, 0 )
      _lRet := .F.
   EndIf 
   
   _nContSema := Dow(M->ZE2_DTCONT)

   If _nContSema <> 1 .And. ; // Domingo
	  _nContSema <> 7 .And. ; // Sábado
	  _nContSema <> 6         // Sexta-Feira

      Help( ,, 'Atenção',, 'O preenchimento da data da contagem só é permitido para os dias da semana: Sexta-feira, Sábado e Domingo.' , 1, 0 )
      _lRet := .F.
   EndIf  
EndIf

FWRestArea(_aArea)

Return(_lRet)

/*
===============================================================================================================================
Programa----------: AEST042TOK
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 11/08/201
Descrição---------: Função para validação da chave, sendo um lançamento de produto por dia
Parametros--------: Nenhum
Retorno-----------: Lógico - .T. dados válidas, .F. dados inválidos
===============================================================================================================================
*/
Static Function AEST042TOK(oModel)

Local _aArea	:= FWGetArea()
Local _nOpc 	:= oModel:GetOperation()
Local _lRet		:= .T.

If (_nopc == 3 .Or. _nopc == 4 ) .And. M->ZE2_PALDES > 0 .And. M->ZE2_QTDPC == 0
		_aInfHlp := {}
		//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
		aAdd( _aInfHlp , { "Foi informado pallet descarte "	, " sem quantidade de peças                  "	} )
		aAdd( _aInfHlp , { "Favor informar quantidade de peças "	, "   "                                         } )

		U_ITCADHLP( _aInfHlp , "AEST04299" )

		_lRet := .F.
EndIf

If _nOpc == 3 .And. _lRet	//Inclusão
	DBSelectArea("ZE2")
	DBSetOrder(3)
	If DBSeek(xFilial("ZE2") + M->ZE2_PRODUT + DToS(M->ZE2_DTCONT) + M->ZE2_LOCAL)
		_aInfHlp := {}
		//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
		aAdd( _aInfHlp , { "O produto informado já possui apontamen-"	, "to para esta data e armazém.           "	} )
		aAdd( _aInfHlp , { "Favor informar apenas um produto por da-"	, "ta e armazém."                           } )

		U_ITCADHLP( _aInfHlp , "AEST04201" )

		_lRet := .F.
	EndIf
EndIf

//Na alteração o sistema grava quantidade de alterações realizadas no registro para log.
If _nOpc == 4 .And. _lRet
	RecLock("ZE2",.F.)
		ZE2->ZE2_QTDALT := ZE2->ZE2_QTDALT + 1
		ZE2->ZE2_AUTEST := ZE2->ZE2_PALVAZ / ZE2->ZE2_MEDCON
	MSUnLock()
EndIf

FWRestArea(_aArea)

Return(_lRet)

/*
===============================================================================================================================
Programa----------: AEST042K
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 11/08/201
Descrição---------: Função para informar a média de consumo diário
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST042K()

Local _aArea	:= FWGetArea()
Local _nMedCG	:= 0
Local _nOpcx	:= 0
Local _oDataL
Local _oDataR
Local _oDescL
Local _oDescR
Local _oMedCG
Local _oMedCL
Local _oPalAvL
Local _oPalAvR
Local _oPallPL
Local _oPallPR
Local _oPalToL
Local _oPalToR
Local _oPalVaL
Local _oPalVaR
Local _oPalSuL
Local _oPalSuR
Local _oPLEAL
Local _oPLEAR
Local _oProdL
Local _oProdR
Local _oSButCan
Local _oSButOk
Local _oDlg

DBSelectArea("ZZL")
DBSetOrder(3) //ZZL_FILIAL + ZZL_CODUSU
If DBSeek(xFilial("ZZL") + __cUserId)
	If ZZL->ZZL_MEDCON == "S"
	   If ZE2->ZE2_DTCONT < Date() 
			If ZZL->ZZL_ALTDTA == "N"
               _aInfHlp := {}
			   //                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
			   aAdd( _aInfHlp , { "Usuário logado não tem permissão para a-"	, "lterar registro com data anterior a atual"	} )
			   aAdd( _aInfHlp , { "Favor solicitar acesso junto ao respon- "	, "sável."                                      } )
	
			   U_ITCADHLP( _aInfHlp , "AEST04205" )
				
			   FWRestArea(_aArea)
			   Return
			EndIf
		EndIf

		DEFINE MSDIALOG _oDlg TITLE "Média Consumo Diário" FROM 000, 000  TO 110, 700 COLORS 0, 16777215 PIXEL
		
			@ 005, 006 Say _oProdL PROMPT "Produto:" SIZE 022, 007 OF _oDlg COLORS 0, 16777215 PIXEL
		    @ 005, 030 Say _oProdR PROMPT ZE2->ZE2_PRODUT SIZE 049, 007 OF _oDlg COLORS 16711680, 16777215 PIXEL
		
		    @ 005, 094 Say _oDescL PROMPT "Descrição:" SIZE 028, 007 OF _oDlg COLORS 0, 16777215 PIXEL
		    @ 005, 122 Say _oDescR PROMPT ZE2->ZE2_DESCRI SIZE 140, 007 OF _oDlg COLORS 16711680, 16777215 PIXEL
		
		    @ 005, 266 Say _oDataL PROMPT "Data Contagem:" SIZE 037, 007 OF _oDlg COLORS 0, 16777215 PIXEL
		    @ 005, 306 Say _oDataR PROMPT ZE2->ZE2_DTCONT SIZE 037, 007 OF _oDlg COLORS 16711680, 16777215 PIXEL
		
		    @ 021, 006 Say _oPallPL PROMPT "Pall.c/Prod:" SIZE 036, 007 OF _oDlg COLORS 0, 16777215 PIXEL
		    @ 021, 042 Say _oPallPR PROMPT AllTrim(Transform(ZE2->ZE2_PALCPR,PesqPict("ZE2","ZE2_PALCPR"))) SIZE 048, 007 OF _oDlg COLORS 16711680, 16777215 PIXEL
		
		    @ 021, 094 Say _oPLEAL PROMPT "Pal.Emb.Almx:" SIZE 036, 007 OF _oDlg COLORS 0, 16777215 PIXEL
		    @ 021, 130 Say _oPLEAR PROMPT AllTrim(Transform(ZE2->ZE2_PALCEA,PesqPict("ZE2","ZE2_PALCEA"))) SIZE 048, 007 OF _oDlg COLORS 16711680, 16777215 PIXEL
		
		    @ 021, 182 Say _oPalAvL PROMPT "Pallet Avari:" SIZE 031, 007 OF _oDlg COLORS 0, 16777215 PIXEL
		    @ 021, 214 Say _oPalAvR PROMPT AllTrim(Transform(ZE2->ZE2_PALAVA,PesqPict("ZE2","ZE2_PALAVA"))) SIZE 048, 007 OF _oDlg COLORS 16711680, 16777215 PIXEL
		
		    @ 021, 266 Say _oPalVaL PROMPT "Pallet Vazio:" SIZE 031, 007 OF _oDlg COLORS 0, 16777215 PIXEL
		    @ 021, 298 Say _oPalVaR PROMPT AllTrim(Transform(ZE2->ZE2_PALVAZ,PesqPict("ZE2","ZE2_PALVAZ"))) SIZE 048, 007 OF _oDlg COLORS 16711680, 16777215 PIXEL

			@ 037, 006 Say _oPalSuL PROMPT "Pallet Sujo:" SIZE 031, 007 OF _oDlg COLORS 0, 16777215 PIXEL
		    @ 037, 038 Say _oPalSuR PROMPT AllTrim(Transform(ZE2->ZE2_PALVAZ,PesqPict("ZE2","ZE2_PALVAZ"))) SIZE 048, 007 OF _oDlg COLORS 16711680, 16777215 PIXEL
		
		    @ 037, 094 Say _oPalToL PROMPT "Pallet Total:" SIZE 031, 007 OF _oDlg COLORS 0, 16777215 PIXEL
		    @ 037, 130 Say _oPalToR PROMPT AllTrim(Transform(ZE2->ZE2_PALTOT,PesqPict("ZE2","ZE2_PALTOT"))) SIZE 048, 007 OF _oDlg COLORS 16711680, 16777215 PIXEL
		
		    @ 037, 182 Say _oMedCL PROMPT "Med.Cons.Dia:" SIZE 038, 007 OF _oDlg COLORS 33023, 16777215 PIXEL
		    @ 037, 220 MSGET _oMedCG VAR _nMedCG SIZE 060, 010 OF _oDlg PICTURE "@E 9,999,999,999.999" COLORS 0, 16777215 PIXEL
		
			DEFINE SBUTTON _oSButCan	FROM 037, 320 Type 02 OF _oDlg ENABLE ACTION (_oDlg:End())
			DEFINE SBUTTON _oSButOk		FROM 037, 288 Type 01 OF _oDlg ENABLE ACTION (_nOpcx := 1, _oDlg:End())
		
		ACTIVATE MSDIALOG _oDlg CENTERED

		If _nOpcx == 1
			RecLock("ZE2",.F.)
				ZE2->ZE2_MEDCON := _nMedCG
				ZE2->ZE2_AUTEST := ZE2->ZE2_PALVAZ / _nMedCG
			MSUnLock()
			U_ITMsg("Média de Consumo Diário foi gravado com sucesso!","Atenção",,1)
		EndIf
	Else
		_aInfHlp := {}
		//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
		aAdd( _aInfHlp , { "Usuário logado não tem permissão para u-"	, "tilizar esta rotina.                    "	} )
		aAdd( _aInfHlp , { "Favor solicitar acesso junto ao respon- "	, "sável."                                      } )

		U_ITCADHLP( _aInfHlp , "AEST04203" )
	EndIf
Else
	_aInfHlp := {}
	//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
	aAdd( _aInfHlp , { "Usuário logado não tem permissão para u-"	, "tilizar esta rotina.                    "	} )
	aAdd( _aInfHlp , { "Favor solicitar acesso junto ao respon- "	, "sável."                                      } )

	U_ITCADHLP( _aInfHlp , "AEST04203" )
EndIf

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: AEST042Z
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 11/08/201
Descrição---------: Função para visualização da quantidade de vezes que o registro foi alterado
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST042Z()

Local _aArea	:= FWGetArea()
Local _oDataL
Local _oDataR
Local _oDescL
Local _oDescR
Local _oProdL
Local _oProdR
Local _oQtdAL
Local _oQtdAR
Local _oSButOk
Local _oDlg

DBSelectArea("ZZL")
DBSetOrder(3) //ZZL_FILIAL + ZZL_CODUSU
If DBSeek(xFilial("ZZL") + __cUserId)
	If ZZL->ZZL_QTDALT == "S"
		DEFINE MSDIALOG _oDlg TITLE "Visualização de Log" FROM 000, 000  TO 080, 490 COLORS 0, 16777215 PIXEL
			@ 005, 006 Say _oProdL PROMPT "Produto:" SIZE 022, 007 OF _oDlg COLORS 0, 16777215 PIXEL
		    @ 005, 030 Say _oProdR PROMPT ZE2->ZE2_PRODUT SIZE 049, 007 OF _oDlg COLORS 16711680, 16777215 PIXEL
		
		    @ 005, 094 Say _oDescL PROMPT "Descrição:" SIZE 028, 007 OF _oDlg COLORS 0, 16777215 PIXEL
		    @ 005, 122 Say _oDescR PROMPT ZE2->ZE2_DESCRI SIZE 135, 007 OF _oDlg COLORS 16711680, 16777215 PIXEL
		
		    @ 021, 006 Say _oDataL PROMPT "Data Contagem:" SIZE 037, 007 OF _oDlg COLORS 0, 16777215 PIXEL
		    @ 021, 046 Say _oDataR PROMPT ZE2->ZE2_DTCONT SIZE 037, 007 OF _oDlg COLORS 16711680, 16777215 PIXEL

			@ 021, 094 Say _oQtdAL PROMPT "Qtd.Alterações:" SIZE 038, 007 OF _oDlg COLORS 33023, 16777215 PIXEL
		    @ 021, 140 Say _oQtdAR PROMPT  AllTrim(Transform(ZE2->ZE2_QTDALT,PesqPict("ZE2","ZE2_QTDALT"))) SIZE 048, 007 OF _oDlg COLORS 33023, 16777215 PIXEL

			DEFINE SBUTTON _oSButOk	FROM 021, 210 Type 01 OF _oDlg ENABLE ACTION (_oDlg:End())
		ACTIVATE MSDIALOG _oDlg CENTERED
    Else
    	_aInfHlp := {}
		//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
		aAdd( _aInfHlp , { "Usuário logado não tem permissão para u-"	, "tilizar esta rotina.                    "	} )
		aAdd( _aInfHlp , { "Favor solicitar acesso junto ao respon- "	, "sável."                                      } )

		U_ITCADHLP( _aInfHlp , "AEST04203" )
	EndIf
Else
	_aInfHlp := {}
	//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
	aAdd( _aInfHlp , { "Usuário logado não tem permissão para u-"	, "tilizar esta rotina.                    "	} )
	aAdd( _aInfHlp , { "Favor solicitar acesso junto ao respon- "	, "sável."                                      } )

	U_ITCADHLP( _aInfHlp , "AEST04203" )
EndIf

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: AEST042Y
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 11/08/201
Descrição---------: Função criada para fazer a alteração do registro seleciona, e validação de alteração com data inferior a
------------------: a data atual
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST042Y()

Local _aArea := FWGetArea()

DBSelectArea("ZZL")
DBSetOrder(3) //ZZL_FILIAL + ZZL_CODUSU
If DBSeek(xFilial("ZZL") + __cUserId)
	If ZE2->ZE2_DTCONT < Date() 
		If ZZL->ZZL_ALTDTA == "N"
			_aInfHlp := {}
			//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
			aAdd( _aInfHlp , { "Usuário logado não tem permissão para a-"	, "lterar registro com data anterior a atual"	} )
			aAdd( _aInfHlp , { "Favor solicitar acesso junto ao respon- "	, "sável."                                      } )

			U_ITCADHLP( _aInfHlp , "AEST04204" )

			FWRestArea(_aArea)
			Return
		EndIf
	EndIf

	FWExecView("Alterar","VIEWDEF.AEST042",4,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,/*nPercReducao*/)
Else
	_aInfHlp := {}
	//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
	aAdd( _aInfHlp , { "Usuário logado não tem permissão para u-"	, "tilizar esta rotina.                    "	} )
	aAdd( _aInfHlp , { "Favor solicitar acesso junto ao respon- "	, "sável."                                      } )

	U_ITCADHLP( _aInfHlp , "AEST04203" )
EndIf

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: AEST042X7
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 20/08/2015
Descrição---------: Função criada para fazer a validação da digitação das datas.
Parametros--------: Nenhum
Retorno-----------: Lógico - .T. dados válidas, .F. dados inválidos
===============================================================================================================================
*/
User Function AEST042X7(_cProduto)

Local _aArea	:= FWGetArea()
Local _cRet		:= ""

DBSelectArea("SB5")
DBSetOrder(1)
If DBSeek(xFilial("SB5") + M->ZE2_PRODUT)
	DBSelectArea("SB1")
	DBSetOrder(1)
	If DBSeek(xFilial("SB1") + M->ZE2_PRODUT)
		_cRet := AllTrim(SB1->B1_DESC)
	Else
		_aInfHlp := {}
		//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
		aAdd( _aInfHlp , { "O produto informado não foi encontrado."	, "                                     "	} )
		aAdd( _aInfHlp , { "Favor informar um produto válido.      "	, ""                                        } )

		U_ITCADHLP( _aInfHlp , "AEST04202" )

		_cRet := ""
	EndIf
Else
	_aInfHlp := {}
	//                 |....:....|....:....|....:....|....:....|      |....:....|....:....|....:....|....:....|
	aAdd( _aInfHlp , { "O produto informado não foi encontrado."	, "                                     "	} )
	aAdd( _aInfHlp , { "Favor informar um produto válido.      "	, ""                                        } )

	U_ITCADHLP( _aInfHlp , "AEST04202" )

	_cRet := ""
EndIf

FWRestArea(_aArea)

Return(_cRet)

/*
===============================================================================================================================
Programa----------: AESTS42 / U_AESTS42
Autor-------------: Alex Wallauer.
Data da Criacao---: 24/06/2022
Descrição---------: Workflow que monitora os PC que já tem o xml e Pré-NF .Chamado 39415
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AESTS42()

Local nI,M       := 0
Local _aParRet   := {}
Local _aParAux   := {}
Local _bOK       := {|| .T. }
Local _lRet      := .F.
Private _lTela   := .T.

SET DATE FORMAT TO "DD/MM/YYYY"

//Testa se esta sendo rodado do menu
If Select('SX3') == 0
   RPCSetType( 3 )					//Não consome licensa de uso
	
   RpcSetEnv('01','01',,,,GetEnvServer(),{ "ZE2" })
   sleep( 1000 )					//Aguarda 5 segundos para que as jobs IPC subam.
	
   _lTela := .F.
   If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
	  MV_PAR01 := Date() 
	  MV_PAR02 := "sistema@italac.com.br"
	  MV_PAR03 := "01;02;03;04;09;0A;10;20;23;30;40;90;91"
	  MV_PAR04 := 2
   Else
	  MV_PAR01 := Date() 
	  MV_PAR02 := ""
	  MV_PAR03 := ""
	  MV_PAR04 := 1
   EndIf
Else
	MV_PAR01 := Date()
	MV_PAR02 := Space(200)
	MV_PAR03 := Space(50)
	MV_PAR04 := 2

   aAdd( _aParAux , { 1 , "Data de Inclusao"	  , MV_PAR01, "@D"	, ""	, ""	, "" , 060 , .T. } )
   aAdd( _aParAux , { 1 , "E-mail Destino"	      , MV_PAR02, "@E"	, ""	, ""	, "" , 100 , .F. } )
   aAdd( _aParAux , { 1 , "Filiais"               , MV_PAR03, "!@"	, ""	, "LSTFIL","", 060 , .F. } )
   aAdd( _aParAux , { 3 , "Enmviar p/ User. WF"   , MV_PAR04, {"Sim","Nao"} , 40, "", .T., .T. , .T. } )

   For nI := 1 To Len( _aParAux )
	    aAdd( _aParRet , _aParAux[nI][03] )
   Next nI
                         //aParametros, cTitle                                , @aRet    ,[bOk], [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ] 
   If !ParamBox( _aParAux , "WK que monitora Pallet Chep" , @_aParRet, _bOK, /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
	   Return .F.
   EndIf
   
EndIf

_cTimeIni  := Time()

_aEmail:={}
DBSelectArea('ZZL')
If ZZL->(FIELDPOS("ZZL_FLEVPA")) > 0 .And. MV_PAR04 = 1
    ZZL->( Dbsetfilter({ | | !Empty(ZZL->ZZL_FLEVPA) }, '!Empty(ZZL->ZZL_FLEVPA)') )
    ZZL->( DBGoTop() )
    While .NOT. ZZL->( Eof() )
    	aAdd(_aEmail,{AllTrim( ZZL->ZZL_EMAIL ),AllTrim(  ZZL->ZZL_FLEVPA )})
    	ZZL->( DBSkip() )
    EndDo
    ZZL->(DBCLEARFILTER())
EndIf

If !Empty(MV_PAR02) .And. !Empty(MV_PAR03)
   aAdd(_aEmail,{AllTrim( MV_PAR02 ),AllTrim(  MV_PAR03 )})
EndIf

If _lTela
   For M := 1 TO Len(_aEmail)
   	   FWMsgRun( ,{|oProc|  _lRet := AESTS42EM(oProc,_aEmail[M,1],_aEmail[M,2] ) } , "Hora Inicial: "+_cTimeIni+" Lendo Cheps a partir de: "+DToC(MV_PAR01))
   Next
Else
	//Atualização tabela SM2
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "AEST042"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "AEST04201"/*cMsgId*/, "AEST04201 - INICIO DO PROCESSAMENTO - Hora Inicial: "+_cTimeIni/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	
   For M := 1 TO Len(_aEmail)
   	   AESTS42EM(,_aEmail[M,1],_aEmail[M,2])
   Next

   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "AEST042"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "AEST04202"/*cMsgId*/, "AEST04202 - FIM DO PROCESSAMENTO - Hora Final: "+TIME()/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	
   RpcClearEnv() //Libera o Ambiente
EndIf

SET DATE FORMAT TO "DD/MM/YY"

Return .T.

/*
===============================================================================================================================
Programa----------: AESTS42EM
Autor-------------: Alex Wallauer
Data da Criacao---: 24/06/2022
Descrição---------: Rotina de envio do email
Parametros--------: oProc = objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AESTS42EM(oProc,_cEmail,_cFilial)

Local _aConfig	  := {}
Local _cEmlLog	  := ""
Local _cMsgEml	  := ""
Local _cGetLista := ""
Local _aCab      := {}
Local _aSizes    := {}
Local cGetCc	  := ""
Local cGetPara	  := ""
Local cGetAssun  := "Workflow de Pallet Chep incluidos no dia "+DToC(MV_PAR01)
Local _cTit      := "Monitoramento de inventario diario de Pallet Chep"
Local _nCont     := 0
Local _aDados    := {}

If oProc <> Nil
	oProc:cCaption := ("Lendo a SELECT...")
	ProcessMessages()
EndIf

//           01       02            03        04            05                       06                       07                      08                      09              10                  11                    12                   13              14
_aSizes := {"10"    ,"07"         ,"15"     ,"07"         ,"07"                    ,"07"                    ,"07"                   ,"07"                   ,"07"           ,"07"               ,"07"                 ,"07"                ,"07"           ,"07"            }  
_aCab   := {"Filial","Dt.Contagem","Produto","Dt.inclusao","Qtde.Pallets_Avariados","Qtde.Pallets_c/_Embal.","Qtde.Pallets_c/_prod.","Qtde.Pallets_Descarte","Qtde.de_Peças","Qtde.Pallets_Sujo","Qtde.Pallets_Vazios","Qtde.Total_Pallets","Media_Consumo","Dias_Autonomia"}  
/*
"Filial","Dt Contagem","Produto","Dt inclusao","Qtde Pallets Avariados","Qtde Pallets c/ Embal.","Qtde Pallets c/ prod.","Qtde Pallets Descarte","Qtde de Peças","Qtde Pallets Sujo","Qtde Pallets Vazios","Qtde Total Pallets","Media Consumo","Dias Autonomia"*/
_aDados    := {}
_aDados    := AESTS42QRY(oProc)//PROCESSAMENTO
_nTotal    := Len(_aDados)

If _nTotal > 0
	If _lTela//
       _cMsgTop:="Par. 1: "+AllTrim(AllToChar(MV_PAR01))+" Par. 2: "+AllTrim(AllToChar(MV_PAR02))+" Par. 3: "+AllTrim(AllToChar(MV_PAR03))+" -  H.I.: "+_cTimeIni+" H.F.: "+TIME()+" - TODAS AS FILIAIS ESTAO LISTADAS AQUI"
       If Len(_aDados) > 0 .And. !U_ITListBox( cGetAssun  , _aCab   , _aDados    , .T. , 1 , _cMsgTop)
	      Return .F.
	   EndIf	
	EndIf	
Else
   If _lTela
      U_ITMsg("Não há dados para listar.","Envio do E-MAIL",,3)
   EndIf
EndIf

//Logo Italac
_cMsgEml := '<html>'
_cMsgEml += '<head><title>'+_cTit+'</title></head>'
_cMsgEml += '<body>'
_cMsgEml += '<style Type="text/css"><!--'
_cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
_cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
_cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
_cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:11px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
_cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:10px; V-align:middle; margin-right: 13px; margin-left: 15px; background-color: #FFFFFF; }'
_cMsgEml += '--></style>'
_cMsgEml += '<center>'
_cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="600" height="50"><br>'
_cMsgEml += '<br>'

//Celula Azul para Título
_cMsgEml += '<table class="bordasimples" width="800">'
_cMsgEml += '    <tr>'
_cMsgEml += '	     <td class="titulos"><center>'+_cTit+'</center></td>'
_cMsgEml += '	 </tr>'
If Len(_aDados) = 0
   _aFilial:=StrTokArr(_cFilial,";")
   _cFiliais:=""
   
   For _nCont := 1 to Len(_aFilial)
	   _cFiliais += "<br>"+_aFilial[_nCont]+ " - " + AllTrim(FWFilialName(cEmpAnt, _aFilial[_nCont], 1 ))
   Next

   _cMsgEml += '    <tr>'
   _cMsgEml += '	     <td class="titulos"><left>Não houve laçamento de inventário no dia '+DToC(DATE())+' de pallet Chep na(s) unidade(s): '+_cFiliais+'</center></td>'
   _cMsgEml += '	 </tr>'
EndIf
_cMsgEml += '</table>'
_cMsgEml += '<br>'

If Len(_aDados) > 0
   _cMsgEml += '<br>'
   _cMsgEml += '<table class="bordasimples" width="3100">'
   _cMsgEml += '    <tr>'
   _cMsgEml += '		<td align="left" colspan="'+AllTrim(Str(Len(_aSizes)))+'" class="grupos"><b>'+cGetAssun+'</b></td>'
   _cMsgEml += '    </tr>'
   _cMsgEml += '    <tr>'
   _cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[01]+'%"><b>'+_aCab[01]+'</b></td>'
   _cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[02]+'%"><b>'+_aCab[02]+'</b></td>'
   _cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[03]+'%"><b>'+_aCab[03]+'</b></td>'
   _cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[04]+'%"><b>'+_aCab[04]+'</b></td>'
   _cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[05]+'%"><b>'+_aCab[05]+'</b></td>'
   _cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[06]+'%"><b>'+_aCab[06]+'</b></td>'
   _cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[07]+'%"><b>'+_aCab[07]+'</b></td>'
   _cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[08]+'%"><b>'+_aCab[08]+'</b></td>'
   _cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[09]+'%"><b>'+_aCab[09]+'</b></td>'
   _cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[10]+'%"><b>'+_aCab[10]+'</b></td>'
   _cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[11]+'%"><b>'+_aCab[11]+'</b></td>'
   _cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[12]+'%"><b>'+_aCab[12]+'</b></td>'
   _cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[13]+'%"><b>'+_aCab[13]+'</b></td>'
   _cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[14]+'%"><b>'+_aCab[14]+'</b></td>'
   _cMsgEml += '    </tr>'
   _cMsgEml += '    #LISTA#'
   _cMsgEml += '</table>'
   
   _cGetLista := ""
   _nTot:=nConta:=0
   _nTot:=Len(_aDados)
   _cTot:=AllTrim(Str(_nTot))
EndIf

For _nCont := 1 To Len(_aDados)
	If oProc <> Nil
       nConta++
	   oProc:cCaption := ('1/2-Montando e-mail: '+AllTrim(Str(nConta))+" de "+_cTot )
	   ProcessMessages()
	EndIf

	If !LEFT(_aDados[_nCont][01],2) $ _cFilial
	   Loop
	EndIf

	_cGetLista += '    <tr>'
	_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[01]+'%">'+ _aDados[_nCont][01] +'</td>' 
	_cGetLista += '      <td class="itens" align="center" width="'+_aSizes[02]+'%">'+ _aDados[_nCont][02] +'</td>' 
	_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[03]+'%">'+ _aDados[_nCont][03] +'</td>' 
	_cGetLista += '      <td class="itens" align="center" width="'+_aSizes[04]+'%">'+ _aDados[_nCont][04] +'</td>'
	_cGetLista += '      <td class="itens" align="right"  width="'+_aSizes[05]+'%">'+ _aDados[_nCont][05] +'</td>'
	_cGetLista += '      <td class="itens" align="right"  width="'+_aSizes[06]+'%">'+ _aDados[_nCont][06] +'</td>'
	_cGetLista += '      <td class="itens" align="right"  width="'+_aSizes[07]+'%">'+ _aDados[_nCont][07] +'</td>'
	_cGetLista += '      <td class="itens" align="right"  width="'+_aSizes[08]+'%">'+ _aDados[_nCont][08] +'</td>' 
	_cGetLista += '      <td class="itens" align="right"  width="'+_aSizes[09]+'%">'+ _aDados[_nCont][09] +'</td>' 
	_cGetLista += '      <td class="itens" align="right"  width="'+_aSizes[10]+'%">'+ _aDados[_nCont][10] +'</td>' 
	_cGetLista += '      <td class="itens" align="right"  width="'+_aSizes[11]+'%">'+ _aDados[_nCont][11] +'</td>' 
	_cGetLista += '      <td class="itens" align="right"  width="'+_aSizes[12]+'%">'+ _aDados[_nCont][12] +'</td>' 
	_cGetLista += '      <td class="itens" align="right"  width="'+_aSizes[13]+'%">'+ _aDados[_nCont][13] +'</td>' 
	_cGetLista += '      <td class="itens" align="right"  width="'+_aSizes[14]+'%">'+ _aDados[_nCont][14] +'</td>' 
	_cGetLista += '    </tr>'			
Next

_cMsgEml := StrTran(_cMsgEml,"#LISTA#",_cGetLista)

_cMsgEml += '</center>'
_cMsgEml += '<br>'
_cMsgEml += '<br>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
_cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [AEST042]</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '</body>'
_cMsgEml += '</html>'

If oProc <> Nil
	oProc:cCaption := ("2/2-Enviando P/ e-mail: "+_cEmail)
	ProcessMessages()
EndIf

cAttach := NIL
_aConfig:= U_ITCFGEML('')
cGetPara:= _cEmail

// Chama a função para envio do e-mail
//ITEnvMail(cFrom       ,cEmailTo ,_cEmailCo,cEmailBcc,cAssunto ,cMensagem,cAttach,cAccount    ,cPassword   ,cServer     ,cPortCon    ,lRelauth     ,cUserAut     ,cPassAut     ,cLogErro)
U_ITENVMAIL(_aConfig[01], cGetPara,   cGetCc,       "",cGetAssun, _cMsgEml,cAttach,_aConfig[01], _aConfig[02],_aConfig[03],_aConfig[04],_aConfig[05],_aConfig[06],_aConfig[07], @_cEmlLog )

If _lTela
    bBloco:=NIL
	_cBotao:=""
    U_ITMsg(_cEmlLog+CHR(13)+CHR(10)+'Envio de E-mail P/ '+cGetPara,;
            'Resultdo do Envio de E-mail ',;
            _cBotao,3,,,,,,bBloco)
EndIf

Return .T.


/*
===============================================================================================================================
Programa----------: AESTS42QRY
Autor-------------: Alex Wallauer
Data da Criacao---: 24/06/2022
Descrição---------: Gera a lista de dados
Parametros--------: oProc
Retorno-----------: _cGetLista = Lista dos dados
===============================================================================================================================
*/  
Static Function AESTS42QRY(oProc)

Local _cAlias   := '' 
Local _aDados   := {}

_cAlias := GetNextAlias()

_cQuery:=" SELECT ZE2.R_E_C_N_O_ NRRECDS "
_cQuery+="  FROM "+RETSQLNAME('ZE2') +" ZE2 "
_cQuery+="   WHERE ZE2.D_E_L_E_T_  = ' ' "
_cQuery+="     AND ZE2.ZE2_DTINCL = '"+DToS(MV_PAR01)+"'"

MPSysOpenQuery( _cQuery,_cAlias )

DBSelectArea(_cAlias)
_nTot:=nConta:=0
COUNT TO _nTot
_cTot:=AllTrim(Str(_nTot))
_aDados:={}

SC7->(DBSetOrder(1))
(_cAlias)->(DBGoTop())
If !(_cAlias)->(Eof())
	While !(_cAlias)->(Eof())

	   If oProc <> Nil
          nConta++
	      oProc:cCaption := ('Lendo ZZ2: '+AllTrim(Str(nConta))+" de "+_cTot )
	      ProcessMessages()
	   EndIf

       ZE2->(DBGoTo((_cAlias)->NRRECDS)) 		
/*
Filial (Nome da unidade); ZE2_FILIAL
Data da contagem (ZE2_DTCONT);
Produto (ZE2_PRODUT);
Descrição (ZE2_DESCRI);
Data de inclusão (ZE2_DTINCL);
Qtde Pallets avariados (ZE2_PALAVA);
Qtde Pallets c/ embalagem (ZE2_PALCEA);
Qtde Pallets c/ produtos (ZE2_PALCPR);
Qtde Pallets descarte (ZE2_PALDES); caso esse campo seja > 0 mostrar tb : "Qtde de peças" (ZE2_QTDPC)
Qtde Pallets sujo (ZE2_PALSUJ);
Qtde Pallets vazios (ZE2_PALVAZ);
Qtde Total de Pallets (ZE2_PALTOT);
Media de consumo (ZE2_MEDCON);
Dias de autonomia (ZE2_AUTEST);
*/
	  aAdd(_aDados,{ZE2->ZE2_FILIAL + " - " + AllTrim(FWFilialName(cEmpAnt, ZE2->ZE2_FILIAL, 1 )),;//01
					DToC(ZE2->ZE2_DTCONT),;                         //02
					ZE2->ZE2_PRODUT+" - "+AllTrim(ZE2->ZE2_DESCRI),;//03
					DToC((ZE2->ZE2_DTINCL)) ,;                      //04
					TRANSF(ZE2->ZE2_PALAVA,'@E 9,999,999,999')    ,;//05
					TRANSF(ZE2->ZE2_PALCEA,'@E 9,999,999,999')    ,;//06
					TRANSF(ZE2->ZE2_PALCPR,'@E 9,999,999,999')    ,;//07
					TRANSF(ZE2->ZE2_PALDES,'@E 9,999,999,999')    ,;//08
					TRANSF(If(ZE2->ZE2_PALDES>0,ZE2->ZE2_QTDPC,0),'@E 9,999,999,999')    ,;//09
					TRANSF(ZE2->ZE2_PALSUJ,'@E 9,999,999,999')    ,;//10
					TRANSF(ZE2->ZE2_PALVAZ,'@E 9,999,999,999')    ,;//11
					TRANSF(ZE2->ZE2_PALTOT,'@E 9,999,999,999')    ,;//12 
					TRANSF(ZE2->ZE2_MEDCON,'@E 9,999,999,999')    ,;//13
					TRANSF(ZE2->ZE2_AUTEST,'@E 9,999,999,999')    ,;//14
					})
	(_cAlias)->(DBSkip())
	EndDo	
EndIf

(_cAlias)->( DBCloseArea() )

Return _aDados

/*
===============================================================================================================================
Programa----------: AEST042W
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/07/2022
Descrição---------: Habilitar a digitação da data de contagem para os finais de semana.
Parametros--------: Nenhum
Retorno-----------: _lRet = .T. = libera campo para digitação.
                            .F. = Bloqueia campo para digitação.
===============================================================================================================================
*/  
User Function AEST042W()

Local _lRet := .F.

_nDiaSeman := Dow(dDataBase) 
If _nDiaSeman == 2 // Segunda-Feira
	_lRet := .T.
EndIf

Return _lRet 
