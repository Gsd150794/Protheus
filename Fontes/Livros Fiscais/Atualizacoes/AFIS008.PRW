/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Jonathan      |28/09/2020| Chamado 34262. Remoção de bugs apontados pelo Totvs CodeAnalysis
Lucas Borges  |24/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
Lucas Borges  |14/09/2025| Chamado 51799. Implementada função para validar ambiente de teste totvs.framework.environment.Type.get()
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include 'FWMVCDEF.CH'

/*
===============================================================================================================================
Programa--------: AFIS008
Autor-----------: Josué Danich Prestes
Data da Criacao-: 06/11/2017
Descrição-------: Cadastro de regras do Sped 500 - Chamado 21797
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AFIS008()

Local oBrowse := Nil
oBrowse := FWMBrowse():New()

oBrowse:SetAlias("ZGH")
oBrowse:SetDescription("Cadastro de regras do SPED 500")
oBrowse:Activate()

Return(Nil)

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Josué Danich Prestes
Data da Criacao---: 06/11/2017
Descrição---------: Rotina para montagem do modelo de dados para o processamento
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ModelDef()

Local oStruZGH	:= FWFormStruct(1,"ZGH")
Local oModel	:= Nil

oModel := MpFormModel():New('AFIS008M')

oModel:AddFields("ZGHMASTER", , oStruZGH)

oModel:SetPrimaryKey( {'ZGH_FILIAL','ZGH_CLIENT',"ZGH_CLILOJ",'ZGH_FORNER',"ZGH_FORLOJ",'ZGH_GRUPO','ZGH_PRODUT',"ZGH_CFOP","ZGH_TPMOV" } )

Return(oModel)

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Josué Danich Prestes
Data da Criacao---: 06/11/2017
Descrição---------: Rotina para montar a View de Dados para exibição
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ViewDef()

Local oModel	:= FWLoadModel('AFIS008')
Local oStruZGH	:= FWFormStruct(2,'ZGH')
Local oView		:= Nil

oView := FWFormView():New()

oStruZGH:AddGroup( 'GRUPO01' , 'NUMERO DA CONTA CONTABIL'   , '' , 2 )
oStruZGH:AddGroup( 'GRUPO02' , 'AMARRACAO COM O TITULO'     , '' , 2 )
oStruZGH:AddGroup( 'GRUPO03' , 'AMARRACAO COM A NOTA FISCAL', '' , 2 )
oStruZGH:AddGroup( 'GRUPO04' , 'AMARRACAO COM BLOCO M'      , '' , 2 )   
oStruZGH:AddGroup( 'GRUPO05' , 'AMARRACAO COM BLOCO H'      , '' , 2 )

oStruZGH:SetProperty( "ZGH_CONTA"	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )

oStruZGH:SetProperty( "ZGH_NATURE"	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
oStruZGH:SetProperty( "ZGH_NATDES"	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )

oStruZGH:SetProperty( "ZGH_CLIENT"  , MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
oStruZGH:SetProperty( "ZGH_CLILOJ"  , MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
oStruZGH:SetProperty( "ZGH_DESCLI"  , MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
oStruZGH:SetProperty( "ZGH_FORNER"  , MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
oStruZGH:SetProperty( "ZGH_FORLOJ"  , MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
oStruZGH:SetProperty( "ZGH_DESFOR"  , MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
oStruZGH:SetProperty( "ZGH_PRODUT"  , MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
oStruZGH:SetProperty( "ZGH_DPROD"   , MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
oStruZGH:SetProperty( "ZGH_GRUPO"   , MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
oStruZGH:SetProperty( "ZGH_DGRUPO"  , MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
oStruZGH:SetProperty( "ZGH_CFOP"    , MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
oStruZGH:SetProperty( "ZGH_TPMOV"   , MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )

oStruZGH:SetProperty( "ZGH_IMPOST"  , MVC_VIEW_GROUP_NUMBER , 'GRUPO04' )
oStruZGH:SetProperty( "ZGH_ALIQ"    , MVC_VIEW_GROUP_NUMBER , 'GRUPO04' )

oStruZGH:SetProperty( "ZGH_TIPOPD"  , MVC_VIEW_GROUP_NUMBER , 'GRUPO05' )
                      
oView:SetModel(oModel)

oView:AddField('VIEW_ZGH',oStruZGH,"ZGHMASTER")

oView:CreateHorizontalBox( 'BOX001' , 100 )
oView:SetOwnerView( 'VIEW_ZGH' , 'BOX001' )

Return(oView)

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------:Josué Danich Prestes
Data da Criacao---: 06/11/2017
Descrição---------: Rotina para criação do menu da tela principal
Parametros--------: Nenhum
Retorno-----------: _aRotina - Array com as opções de menu
===============================================================================================================================
*/
Static Function MenuDef()

Local _aRotina := {}

ADD OPTION _aRotina Title 'Visualizar'			Action 'VIEWDEF.AFIS008'	OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Incluir'   			Action 'VIEWDEF.AFIS008'	OPERATION 3 ACCESS 0
ADD OPTION _aRotina Title 'Incluir Natureza'	Action 'VIEWDEF.AFIS008' 	OPERATION 3 ACCESS 0
ADD OPTION _aRotina Title 'Alterar'   			Action 'VIEWDEF.AFIS008'	OPERATION 4 ACCESS 0
ADD OPTION _aRotina Title 'Excluir'				Action 'VIEWDEF.AFIS008'	OPERATION 5 ACCESS 0
ADD OPTION _aRotina Title 'Imprimir' 			Action 'VIEWDEF.AFIS008'	OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Simulador'  			Action 'U_AFIS008Teste'	    OPERATION 2 ACCESS 0

Return(_aRotina)

/*
===============================================================================================================================
Programa----------: AFIS008M
Autor-------------: Josué Danich Prestes
Data da Criacao---: 06/11/2017
Descrição---------: Pontos de entrada da rotina
Parametros--------: Nenhum
Retorno-----------: _xret - lógico de retorno
===============================================================================================================================
*/
User Function AFIS008M()

Local aParam     := ParamIXB
Local oObj       := ''
Local cIdPonto   := ''
Local cIdModel   := ''
Local _xret 	 := .T.

oObj       := aParam[1]
cIdPonto   := aParam[2]
cIdModel   := aParam[3]

If cIdPonto == 'MODELPOS' .And. (Inclui .Or. Altera)
	
    If Empty(M->ZGH_NATURE) .And. Empty(M->ZGH_IMPOST) .And. Empty(M->ZGH_ALIQ) .And. Empty(M->ZGH_TIPOPD)
		
		If ( !Empty(AllTrim(oobj:GetValue("ZGHMASTER","ZGH_FORNER"))) .Or. !Empty(AllTrim(oobj:GetValue("ZGHMASTER","ZGH_FORLOJ"))) ) .AND.;
			( !Empty(AllTrim(oobj:GetValue("ZGHMASTER","ZGH_CLIENT"))) .Or. !Empty(AllTrim(oobj:GetValue("ZGHMASTER","ZGH_CLILOJ"))) )
			
			Help( ,, 'Atenção',, 'Forncedor+Loja ou Clente+Loja não podem ser preenchidos ao mesmo tempo!', 1, 0 )
			_xret := .F.
			
		EndIf
		
		If Empty(AllTrim(oobj:GetValue("ZGHMASTER","ZGH_GRUPO"))) .And. Empty(AllTrim(oobj:GetValue("ZGHMASTER","ZGH_PRODUT")))
			Help( ,, 'Atenção',, 'Grupo ou produto precisam ser preenchidos!', 1, 0 )
			_xret := .F.
		EndIf
		
		If !Empty(AllTrim(oobj:GetValue("ZGHMASTER","ZGH_GRUPO"))) .And. !Empty(AllTrim(oobj:GetValue("ZGHMASTER","ZGH_PRODUT")))
			Help( ,, 'Atenção',, 'Grupo e produto não podem ser preenchidos ao mesmo tempo!', 1, 0 )
			_xret := .F.
		EndIf
		
		If Empty(AllTrim(oobj:GetValue("ZGHMASTER","ZGH_CFOP"))) .And. Empty(AllTrim(oobj:GetValue("ZGHMASTER","ZGH_TPMOV")))
			Help( ,, 'Atenção',, 'Cfop ou tipo de movimento precisam ser preenchidos!', 1, 0 )
			_xret := .F.
		EndIf
		
		If !Empty(AllTrim(oobj:GetValue("ZGHMASTER","ZGH_CFOP"))) .And. !Empty(AllTrim(oobj:GetValue("ZGHMASTER","ZGH_TPMOV")))
			Help( ,, 'Atenção',, 'Cfop e tipo de movimento não podem ser preenchidos ao mesmo tempo!', 1, 0 )
			_xret := .F.
		EndIf
		
		If  !Empty(AllTrim(oobj:GetValue("ZGHMASTER","ZGH_FORNER"))) .And. !Empty(AllTrim(oobj:GetValue("ZGHMASTER","ZGH_TPMOV"))) .And. AllTrim(oobj:GetValue("ZGHMASTER","ZGH_TPMOV")) # 'E'
			Help( ,, 'Atenção',, 'Quando Forncedor e Tipo de Movimento preenchidos, Tipo de Movimento só pode ser Entrada', 1, 0 )
			_xret := .F.
		EndIf
		If  !Empty(AllTrim(oobj:GetValue("ZGHMASTER","ZGH_CLIENT"))) .And. !Empty(AllTrim(oobj:GetValue("ZGHMASTER","ZGH_TPMOV"))) .And. AllTrim(oobj:GetValue("ZGHMASTER","ZGH_TPMOV")) # 'S'
			Help( ,, 'Atenção',, 'Quando Cliente e Tipo de Movimento preenchidos, Tipo de Movimento só pode ser Saida', 1, 0 )
			_xret := .F.
		EndIf
		
		If  !Empty(AllTrim(oobj:GetValue("ZGHMASTER","ZGH_FORNER"))) .And. !Empty(AllTrim(oobj:GetValue("ZGHMASTER","ZGH_CFOP"))) .And. AllTrim(oobj:GetValue("ZGHMASTER","ZGH_CFOP")) >= "5000"
			Help( ,, 'Atenção',, 'Quando Forncedor e CFOP preenchidos, CFOP só pode menor que 5000', 1, 0 )
			_xret := .F.
		EndIf
		If  !Empty(AllTrim(oobj:GetValue("ZGHMASTER","ZGH_CLIENT"))) .And. !Empty(AllTrim(oobj:GetValue("ZGHMASTER","ZGH_CFOP"))) .And. AllTrim(oobj:GetValue("ZGHMASTER","ZGH_CFOP")) < "5000"
			Help( ,, 'Atenção',, 'Quando Cliente e CFOP preenchidos, CFOP só pode maior que 5000', 1, 0 )
			_xret := .F.
		EndIf
		
		ZGH->(DBSetOrder(3))//ZGH_FILIAL+ZGH_CLIENT+ZGH_CLILOJ+ZGH_FORNER+ZGH_FORLOJ+ZGH_GRUPO+ZGH_PRODUT+ZGH_CFOP+ZGH_TPMOV
		If  Inclui .And. ZGH->(DBSeek(xFilial("ZGH")+ M->(ZGH_CLIENT+ZGH_CLILOJ+ZGH_FORNER+ZGH_FORLOJ+ZGH_GRUPO+ZGH_PRODUT+ZGH_CFOP+ZGH_TPMOV) )) .And. Empty(M->ZGH_TIPOPD)
			Help( ,, 'Atenção',, 'Chave Cliente + Fornecedor + Grupo + Produto + CFOP + Tp Movimento já cadastrados', 1, 0 )
			_xret := .F.
		EndIf
		
	ElseIf !Empty(M->ZGH_NATURE)
		
		ZGH->(DBSetOrder(4))//ZGH_FILIAL+ZGH_NATURE
		nSalvaRec:=ZGH->(RECNO())//Para alteração
		If  ZGH->(DBSeek(xFilial("ZGH")+M->ZGH_NATURE )) .And. (Inclui .Or. nSalvaRec <> ZGH->(RECNO()))
			Help( ,, 'Atenção',, 'Natureza já foi cadastrada para outra conta: '+ZGH->ZGH_CONTA, 1, 0 )
			_xret := .F.
		EndIf
		ZGH->(DBGoTo(nSalvaRec))

	ElseIf !Empty(M->ZGH_TIPOPD)
		
		ZGH->(DBSetOrder(6))
		nSalvaRec:=ZGH->(RECNO())//Para alteração
		If ZGH->(DBSeek(xFilial("ZGH")+M->ZGH_TIPOPD)) .And. (Inclui .Or. nSalvaRec <> ZGH->(RECNO()))
			Help( ,, 'Atenção',, 'O TIPO DE PRODUTO já foi cadastrada para outra conta: '+ZGH->ZGH_CONTA, 1, 0 )
			_xret := .F.
		EndIf
		ZGH->(DBGoTo(nSalvaRec))
		
	ElseIf !Empty(M->ZGH_IMPOST) .Or. !Empty(M->ZGH_ALIQ)
		
		ZGH->(DBSetOrder(5))//ZGH_FILIAL+ZGH_IMPOST+ZGH_ALIQ
		nSalvaRec:=ZGH->(RECNO())//Para alteração
		If Empty(M->ZGH_IMPOST) .Or. Empty(M->ZGH_ALIQ)
			Help( ,, 'Atenção',, 'O imposto e a aliquota devem ser informados juntos', 1, 0 )
			_xret := .F.
		ElseIf ZGH->(DBSeek(xFilial("ZGH")+M->ZGH_IMPOST+Str(M->ZGH_ALIQ,7,4))) .And. (Inclui .Or. nSalvaRec <> ZGH->(RECNO()))
			Help( ,, 'Atenção',, 'Imposto + aliquota já cadastrados', 1, 0 )
			_xret := .F.
		EndIf
		ZGH->(DBGoTo(nSalvaRec))

	EndIf
	
	
EndIf

Return _xret

/*
===============================================================================================================================
Programa----------: AFIS008Teste()
Autor-------------: Alex Wallauer
Data da Criacao---: 08/12/2017
Descrição---------: opcao de teste da rotina
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AFIS008Teste()

Local aFixos:={}

aRotina:={}
aAdd( aRotina,	{ "Visualizar" ,"AxVisual"		, 0 , 2})
aAdd( aRotina,	{ "Buscar"     ,"U_AFIS008Busca()"	, 0 , 4})
cCadastro:="Itens da NF do SPEE 500"

aAdd(aFixos,{AVSX3("FT_CLIEFOR" ,5),"FT_CLIEFOR"                                              })
aAdd(aFixos,{AVSX3("FT_LOJA"    ,5),"FT_LOJA"                                                 })
aAdd(aFixos,{AVSX3("FT_CLIENT"  ,5),"FT_CLIENT"                                               })
aAdd(aFixos,{AVSX3("FT_LOJENT"  ,5),"FT_LOJENT"                                               })
aAdd(aFixos,{AVSX3("FT_PRODUTO" ,5),"FT_PRODUTO"                                              })
aAdd(aFixos,{AVSX3("B1_GRUPO"   ,5),{|| E_Field2(SFT->FT_PRODUTO,"SB1",1,"B1_GRUPO") }})
aAdd(aFixos,{AVSX3("FT_TIPOMOV" ,5),"FT_TIPOMOV"                                              })
aAdd(aFixos,{AVSX3("FT_CFOP"    ,5),"FT_CFOP"                                                 })

mBrowse(,,,,"SFT",aFixos)

Return .T.

/*
===============================================================================================================================
Programa----------: AFIS008Busca()
Autor-------------: Alex Wallauer
Data da Criacao---: 08/12/2017
Descrição---------: opcao de teste da rotina
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================*/
User Function AFIS008Busca()

Local cConta
Private _nRecZGH:=0//Usada dentro do PE SPDPIS07

cConta:=ExecBlock("SPDPIS07", .F., .F.,{;
            SFT->FT_FILIAL,;
			SFT->FT_TIPOMOV,;
			SFT->FT_SERIE,;
			SFT->FT_NFISCAL,;
			SFT->FT_CLIEFOR,;
			SFT->FT_LOJA,;
			SFT->FT_ITEM,;
			SFT->FT_PRODUTO})


If _nRecZGH # 0
   ZGH->(DBGoTo( _nRecZGH ) )
   cCadastro:="Registro da conta encontrado: "+cConta
   AxVisual( "ZGH", _nRecZGH , 2 )
Else
   U_ITMsg("Registro da conta NÃO encontrado","Atenção",,3)
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: AFIS008Val()
Autor-------------: Alex Wallauer
Data da Criacao---: 08/12/2017
Descrição---------: Chamado dos valid user dos campos - X3_VLDUSER - Mesmo coisa que o gatilho
Parametros--------: _cCampo: descrição simpres do campo que chamou
Retorno-----------: .T.
===============================================================================================================================*/
User Function AFIS008Val(_cCampo)

Local _oModel:=FWModelActive(),V
Local _aCpo:={"ZGH_FORNER","ZGH_FORLOJ","ZGH_DESFOR","ZGH_CLIENT","ZGH_CLILOJ","ZGH_DESCLI","ZGH_GRUPO","ZGH_DGRUPO",;
              "ZGH_PRODUT","ZGH_DPROD","ZGH_CFOP","ZGH_TPMOV","ZGH_NATURE","ZGH_NATDES","ZGH_TIPOPD"}

For V := 1 TO Len(_aCpo)
    _cCpo:=_aCpo[V]
    _xVal:=&("M->"+_cCpo)
    _oModel:GETVALUE( "ZGHMASTER" , _cCpo  )
Next

Do Case

   Case _cCampo = "NAT"
	    If !Empty(M->ZGH_NATURE) 
           SED->(DBSetOrder(1))
	       If !SED->(DBSeek(xFilial()+M->ZGH_NATURE ))
		      Help( ,, 'Atenção',, "Codigo da Natureza NÃO cadastrada", 1, 0 )
              Return .F.
           EndIf
	       M->ZGH_NATDES:=Posicione("SED",1,xFilial("SED")+M->ZGH_NATURE,"ED_DESCRIC")
	       M->ZGH_TIPOPD := Space(2)  
	    Else
	       M->ZGH_NATDES:=Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_NATDES")))
	    EndIf                    

   Case _cCampo = "For"
	    If !Empty(M->ZGH_FORNER) 
           SA2->(DBSetOrder(1))
	       If !SA2->(DBSeek(xFilial("SA2")+M->ZGH_FORNER+AllTrim(M->ZGH_FORLOJ ) ))
		      Help( ,, 'Atenção',, "Codigo do Fornecedor NÃO cadastrado", 1, 0 )
            Return .F.
           EndIf
	       M->ZGH_DESFOR:=Posicione("SA2",1,xFilial("SA2")+M->ZGH_FORNER+AllTrim(M->ZGH_FORLOJ),"A2_NREDUZ")
	       M->ZGH_CLIENT:=Space(Len(ZGH->ZGH_CLIENT))
           M->ZGH_CLILOJ:=Space(Len(ZGH->ZGH_CLILOJ))
           M->ZGH_DESCLI:=Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_DESCLI")))
           M->ZGH_TIPOPD := Space(2)  
	    Else
	       M->ZGH_FORLOJ:=Space(Len(ZGH->ZGH_FORLOJ))
           M->ZGH_DESFOR:=Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_DESFOR")))
	    EndIf

   Case _cCampo = "CLI"
	    If !Empty(M->ZGH_CLIENT) 
           SA1->(DBSetOrder(1))
	       If !SA1->(DBSeek(xFilial("SA1")+M->ZGH_CLIENT+AllTrim(M->ZGH_CLILOJ) ))
		      Help( ,, 'Atenção',, "Codigo do Cliente NÃO cadastrado", 1, 0 )
            Return .F.
           EndIf
	       M->ZGH_DESCLI:=Posicione("SA1",1,xFilial("SA1")+M->ZGH_CLIENT+AllTrim(M->ZGH_CLILOJ),"A1_NREDUZ")
	       M->ZGH_FORNER:=Space(Len(ZGH->ZGH_FORNER))
           M->ZGH_FORLOJ:=Space(Len(ZGH->ZGH_FORLOJ))
           M->ZGH_DESFOR:=Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_DESFOR")))      
           M->ZGH_TIPOPD := Space(2)  
	    Else
	       M->ZGH_CLILOJ:=Space(Len(ZGH->ZGH_CLILOJ))
           M->ZGH_DESCLI:=Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_DESCLI")))
	    EndIf

   Case _cCampo = "GRU"
	    If !Empty(M->ZGH_GRUPO) 
	       M->ZGH_DGRUPO:=Posicione('SBM',1,xFilial('SBM')+M->ZGH_GRUPO,"BM_DESC")
	       M->ZGH_PRODUT:=Space(Len(ZGH->ZGH_PRODUT))
           M->ZGH_DPROD :=Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_DPROD")))
           M->ZGH_TIPOPD := Space(2)  
           
	    Else
           M->ZGH_DGRUPO:=Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_DGRUPO")))
	    EndIf

   Case _cCampo = "PROD"
	    If !Empty(M->ZGH_PRODUT) 
	       M->ZGH_DPROD :=Posicione('SB1',1,xFilial('SB1')+M->ZGH_PRODUT,"B1_DESC")
	       M->ZGH_GRUPO :=Space(Len(ZGH->ZGH_GRUPO))
           M->ZGH_DGRUPO:=Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_DGRUPO")))   
           M->ZGH_TIPOPD := Space(2)  
	    Else
           M->ZGH_DPROD :=Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_DPROD")))
	    EndIf

   Case _cCampo = "CFOP"
	    If !Empty(M->ZGH_CFOP) 
	       M->ZGH_TPMOV :=Space(Len(ZGH->ZGH_TPMOV))
	       M->ZGH_TIPOPD := Space(2)  
	    EndIf

   Case _cCampo = "TPMOV"
	    If !Empty(M->ZGH_TPMOV) 
	       M->ZGH_CFOP :=Space(Len(ZGH->ZGH_CFOP))  
	       M->ZGH_TIPOPD := Space(2)  
	    EndIf
   
EndCase

If  _cCampo = "ALQ"
	M->ZGH_CLIENT:=Space(Len(ZGH->ZGH_CLIENT))
	M->ZGH_CLILOJ:=Space(Len(ZGH->ZGH_CLILOJ))
	M->ZGH_DESCLI:=Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_DESCLI")))
	M->ZGH_FORNER:=Space(Len(ZGH->ZGH_FORNER))
	M->ZGH_FORLOJ:=Space(Len(ZGH->ZGH_FORLOJ))
	M->ZGH_DESFOR:=Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_DESFOR")))
	M->ZGH_PRODUT:=Space(Len(ZGH->ZGH_PRODUT))
	M->ZGH_DPROD :=Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_DPROD")))
	M->ZGH_GRUPO :=Space(Len(ZGH->ZGH_GRUPO))
	M->ZGH_DGRUPO:=Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_DGRUPO")))
	M->ZGH_TPMOV :=Space(Len(ZGH->ZGH_TPMOV))
	M->ZGH_CFOP  :=Space(Len(ZGH->ZGH_CFOP))
	M->ZGH_NATURE:=Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_NATURE")))
	M->ZGH_NATDES:=Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_NATDES")))
    M->ZGH_TIPOPD:= Space(2)  
ElseIf  _cCampo = "NAT"
	M->ZGH_CLIENT:=Space(Len(ZGH->ZGH_CLIENT))
	M->ZGH_CLILOJ:=Space(Len(ZGH->ZGH_CLILOJ))
	M->ZGH_DESCLI:=Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_DESCLI")))
	M->ZGH_FORNER:=Space(Len(ZGH->ZGH_FORNER))
	M->ZGH_FORLOJ:=Space(Len(ZGH->ZGH_FORLOJ))
	M->ZGH_DESFOR:=Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_DESFOR")))
	M->ZGH_PRODUT:=Space(Len(ZGH->ZGH_PRODUT))
	M->ZGH_DPROD :=Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_DPROD")))
	M->ZGH_GRUPO :=Space(Len(ZGH->ZGH_GRUPO))
	M->ZGH_DGRUPO:=Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_DGRUPO")))
	M->ZGH_TPMOV :=Space(Len(ZGH->ZGH_TPMOV))
	M->ZGH_CFOP  :=Space(Len(ZGH->ZGH_CFOP))
    M->ZGH_IMPOST:=" "
    M->ZGH_ALIQ  :=0
    M->ZGH_TIPOPD := Space(2)  
ElseIf _cCampo = "TIPOPRD" 
	If ! Empty(M->ZGH_TIPOPD)           	   
	   M->ZGH_CLIENT := Space(Len(ZGH->ZGH_CLIENT))
	   M->ZGH_CLILOJ := Space(Len(ZGH->ZGH_CLILOJ))
	   M->ZGH_DESCLI := Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_DESCLI")))
	   M->ZGH_FORNER := Space(Len(ZGH->ZGH_FORNER))
	   M->ZGH_FORLOJ := Space(Len(ZGH->ZGH_FORLOJ))
	   M->ZGH_DESFOR := Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_DESFOR")))
	   M->ZGH_PRODUT := Space(Len(ZGH->ZGH_PRODUT))
	   M->ZGH_DPROD  := Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_DPROD")))
	   M->ZGH_GRUPO  := Space(Len(ZGH->ZGH_GRUPO))
	   M->ZGH_DGRUPO := Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_DGRUPO")))
	   M->ZGH_TPMOV  := Space(Len(ZGH->ZGH_TPMOV))
	   M->ZGH_CFOP   := Space(Len(ZGH->ZGH_CFOP))
	   M->ZGH_NATURE := Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_NATURE")))
	   M->ZGH_NATDES := Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_NATDES")))
    EndIf 
Else
	M->ZGH_NATURE:=Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_NATURE")))
	M->ZGH_NATDES:=Space(Len(_OMODEL:GETVALUE("ZGHMASTER","ZGH_NATDES")))
    M->ZGH_IMPOST:=" "
    M->ZGH_ALIQ  :=0
    M->ZGH_TIPOPD := Space(2)  
EndIf

For V := 1 TO Len(_aCpo)
    _cCpo:=_aCpo[V]
    _xVal:=&("M->"+_cCpo)
    _nTam:=AVSX3(_cCpo,3)//X3_TAMANHO
    _oModel:LoadValue( "ZGHMASTER" , _cCpo , LEFT(_xVal,_nTam) )
Next

Return .T.

/*
===============================================================================================================================
Programa----------: AFIS008Integ()
Autor-------------: Alex Wallauer
Data da Criacao---: 26/12/2017
Descrição---------: Integra arquivo CSV 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AFIS008Integ()

Local aSemSX3  :={} , nI
Private _cFileCSV:="",cNomArq:=""
Private cAliasWK := GetNextAlias()

Private _aCols:={}

_cTimeIni:=Time()

//_cFileCSV := cGetFile( "Documento Texto |*.CSV" ,"Selecione o CSV para apendar e validar",0,"C:\LIXO\AFIS008\",.T.,GETF_LOCALHARD)
_aParAux:={}
_aParRet:={}
MV_PAR81= Space(150)
aAdd( _aParAux , { 1 , "Selecione arquivo .CSV:"		,MV_PAR81, "@!"		, ""	, "DIR"		, "" , 100 , .F. } ) 
For nI := 1 To Len( _aParAux )
	aAdd( _aParRet , _aParAux[nI][03] )
Next
cTitle:="Selecione o CSV para apendar e validar"
//        aParametros,cTitle  ,aRet     ,bOk ,aButtons,lCentered,nPosX,nPosY,oDlgWizard,cLoad,lCanSave,lUserSave
If !ParamBox( _aParAux ,cTitle,@_aParRet,    ,        ,         ,     ,     ,          ,     ,.T.     ,.T. )
	Return .T.
EndIf
_cFileCSV :=MV_PAR01

If !Empty(_cFileCSV)
	
	If !File(_cFileCSV)
		U_ITMsg("Arquivo "+_cFileCSV+" NÃO encontrado","Atenção",,3)
		Return .F.
	EndIf
	
	_cTimeIni:=Time()
	
	aCampos:={}
	//Layout do CSV SEGUIR A ORDEM ABAIXO
	aAdd(aSemSX3,{"ZGH_FILIAL","C",Len(ZGH->ZGH_FILIAL),0})
	aAdd(aSemSX3,{"ZGH_CONTA", "C",Len(ZGH->ZGH_CONTA ),0})
	aAdd(aSemSX3,{"ZGH_CLIENT","C",Len(ZGH->ZGH_CLIENT),0})
	aAdd(aSemSX3,{"ZGH_CLILOJ","C",Len(ZGH->ZGH_CLILOJ),0})
	aAdd(aSemSX3,{"ZGH_FORNER","C",Len(ZGH->ZGH_FORNER),0})
	aAdd(aSemSX3,{"ZGH_FORLOJ","C",Len(ZGH->ZGH_FORLOJ),0})
	aAdd(aSemSX3,{"ZGH_PRODUT","C",Len(ZGH->ZGH_PRODUT),0})
	aAdd(aSemSX3,{"ZGH_GRUPO", "C",Len(ZGH->ZGH_GRUPO ),0})
	aAdd(aSemSX3,{"ZGH_CFOP",  "C",Len(ZGH->ZGH_CFOP  ),0})
	aAdd(aSemSX3,{"ZGH_TPMOV", "C",Len(ZGH->ZGH_TPMOV ),0})
	aAdd(aSemSX3,{"ZGH_NATURE","C",Len(ZGH->ZGH_NATURE),0})
	aAdd(aSemSX3,{"ZGH_TIPOPD","C",Len(ZGH->ZGH_TIPOPD),0})
	aAdd(aSemSX3,{"WK_MARCA"  ,"L",001,0})
	aAdd(aSemSX3,{"WK_MSG"    ,"C",100,0})
	
	
	_oTemp:= FWTemporaryTable():New(cAliasWK,aSemSX3)
	_oTemp:AddIndex("1", {"ZGH_FILIAL","ZGH_CONTA"})
	_oTemp:Create()
	cNomArq:=_oTemp:GetRealName()
	
ElseIf !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento

Else
    Return .F.//********************************* SAI FORA
EndIf

nPosChave:=15//POSICAO DA CHAVE COMPLETA

_nRepet:=0
_cTot  :=""
lRet:=.T.
FWMsgRun( ,{|oproc| lRet:=AFIS008Ler(oproc) } ,"Aguarde... Processando: "+cNomArq )
If !lRet
   (cAliasWK)->(DBCloseArea())
   Return .F.
EndIf
_cTitAux:='REGRAS SPEED 500 - HrI: '+_cTimeIni+" / HrF: "+TIME()+" / Total: "+_cTot+" / Repetidos: "+StrZero(_nRepet,7)+" / Arq.: "+cNomArq

While Len(_aCols) > 0

   _AHEADER:={" ",'FILIAL','CONTA','COD. CLIENTE','LOJA','COD, FORN','LOJA','PRODUTO','GRUPO','CFOP','TIPO','NATUREZA','TP PRODRO','OBSERVACAO',"CHAVE"}
   _ASIZES :={ 10,      30,     40,            40,    30,         40,    30,      50,      40,    40,    30,        50,        30 ,         200,    100}

   nPosResu:=nPosChave-1//POSICAO DA MENSAGEM
   aBotoes:={}                                           
   aAdd( aBotoes , { "" , {|| FWMsgRun(,{ |oProc| AFIS008GRV(oproc,.T.) }, "","") },"","ANALISE dos dados"} )
   aAdd( aBotoes , { "" , {|| AVISO("ATENCAO",oLbxAux:aArray[oLbxAux:nAt][ nPosResu ],{"Fechar"},3) }	, "" , "Ver Resultado"		  } )
//    ITListBox(_cTitAux       , _aHeader, _aCols, _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons )
	_LOK:=U_ITLISTBOX( _cTitAux,_AHEADER , _aCols, .T.      , 4      ,          ,          ,_ASIZES  ,         ,     ,        , aBotoes )
	If _LOK
		If U_ITMsg("Confirma a GRAVACAO dos dados?",'Atenção!',,3,2,2)
           FWMsgRun( ,{|oproc| AFIS008GRV(oproc,.F.) } ,"Aguarde", "Gravando..." )
		Else
		   Loop
		EndIf
	EndIf
	Exit
EndDo

If Len(_aCols) = 0

	_aParAux:={}
	_aParRet:={}
	MV_PAR91:="1-GRAVACAO DOS DADOS"
	
	aAdd( _aParAux , {2,"Escolah uma Opção:",MV_PAR91, {"1-GRAVACAO DOS DADOS",;
	                                                    "2-ANALISE DOS DADOS"},100,".T.",.T.,".T."})
	
	For nI := 1 To Len( _aParAux )
		aAdd( _aParRet , _aParAux[nI][03] )
	Next nI
	
	
	While .T.		
		//        aParametros ,cTitle                 ,aRet      ,bOk                     ,aButtons,lCentered,nPosX,nPosY,oDlgWizard,cLoad,lCanSave,lUserSave
		If ParamBox( _aParAux , "Selecione uma Opcao" , @_aParRet, {|| !Empty(MV_PAR01) } ,        , .T.     ,     ,     ,          ,     , .F.    , .F. )
			
			
			If MV_PAR01 = "1"
				FWMsgRun( ,{|oproc| AFIS008GRV(oproc,.F.) } ,"Aguarde", "Gravando..." )
				Exit
			Else
				FWMsgRun( ,{|oproc| AFIS008GRV(oproc,.T.) } ,"Analisando...", "Analisando..." )
				Loop
			EndIf
			
		EndIf

		Exit

	EndDo
	
EndIf

(cAliasWK)->(DBCloseArea())  
If Type("_otemp") = "O"
   _oTemp:Delete()
EndIf   

Return .T.


/*
===============================================================================================================================
Programa----------: AFIS008Ler()
Autor-------------: Alex Wallauer
Data da Criacao---: 27/12/2017
Descrição---------: Ler e valida arquivo CSV 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIS008Ler(oproc)

Local _cTimeIni:=Time()

If !Empty(_cFileCSV)
   oproc:cCaption := "Apendando, Aguarde... Hora Inicial :"+_cTimeIni+" / Arq.: "+cNomArq
   ProcessMessages()
   If !AFIS008Ape(oProc)
      Return .F.
   EndIf
EndIf

ZGH->(DBSetOrder(3))//ZGH_FILIAL+ZGH_CLIENT+ZGH_CLILOJ+ZGH_FORNER+ZGH_FORLOJ+ZGH_GRUPO+ZGH_PRODUT+ZGH_CFOP+ZGH_TPMOV
_nConta:=(cAliasWK)->(LASTREC())
_cTot:=AllTrim(Str(_nConta))

oproc:cCaption := "Processando, Aguarde... Hora Inicial :"+_cTimeIni+" / Arq.: "+cNomArq
ProcessMessages()

cQuery := "SELECT ZGH.R_E_C_N_O_ ZGH_REC "
cQuery += " FROM "+cNomArq+" ZGH "
cQuery += " WHERE ZGH.D_E_L_E_T_ = ' ' AND ZGH_FILIAL||ZGH_CLIENT||ZGH_CLILOJ||ZGH_FORNER||ZGH_FORLOJ||ZGH_GRUPO||ZGH_PRODUT||ZGH_CFOP||ZGH_TPMOV||ZGH_NATURE||ZGH_TIPOPD IN "
cQuery += "                      (SELECT  (ZGH_FILIAL||ZGH_CLIENT||ZGH_CLILOJ||ZGH_FORNER||ZGH_FORLOJ||ZGH_GRUPO||ZGH_PRODUT||ZGH_CFOP||ZGH_TPMOV||ZGH_NATURE||ZGH_TIPOPD) "
cQuery += "                                FROM "+cNomArq+" ZGH2 WHERE ZGH2.D_E_L_E_T_ = ' ' "
cQuery += "                                GROUP BY (ZGH_FILIAL||ZGH_CLIENT||ZGH_CLILOJ||ZGH_FORNER||ZGH_FORLOJ||ZGH_GRUPO||ZGH_PRODUT||ZGH_CFOP||ZGH_TPMOV||ZGH_NATURE||ZGH_TIPOPD) having COUNT(*) > 1 ) "
cQuery += " ORDER BY ZGH_FILIAL,ZGH_CLIENT,ZGH_CLILOJ,ZGH_FORNER,ZGH_FORLOJ,ZGH_GRUPO,ZGH_PRODUT,ZGH_CFOP,ZGH_TPMOV,ZGH_NATURE,ZGH_TIPOPD,ZGH_CONTA "

cAliasAux:="ZHG_QRY"
If Select(cAliasAux) > 0
   (cAliasAux)->(DBCloseArea())
EndIf
		
dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery),cAliasAux, .F., .T.)

COUNT TO _nConta

If _nConta = 0
	U_ITMsg("Não foi encontrado resgistros com Chave repetida.","ANALISE DE CHAVES DUPLICADAS",,2)
	Return .T.
EndIf

_cTot2:=AllTrim(Str(_nConta))

_nConta:=0
_nRepet:=0
_aCols:={}
DBSelectArea( cAliasWK )

(cAliasAux)->(DBGoTop())
While (cAliasAux)->(!Eof())

    (cAliasWK)->(DBGoTo( (cAliasAux)->ZGH_REC ))
    _nConta++
    oproc:cCaption := "HI: "+_cTimeIni+" - Validando Regra: "+StrZero(_nConta,7)+" / "+_cTot2+" - "+StrZero(_nRepet,7)+" / Arq.: "+cNomArq
    ProcessMessages()

   If (_nPos2:=aScan(_aCols,{|C|C[nPosChave]==(cAliasWK)->(ZGH_FILIAL+;
                                                           ZGH_CLIENT+;
                                                           ZGH_CLILOJ+;
                                                           ZGH_FORNER+;
                                                           ZGH_FORLOJ+;
                                                           ZGH_GRUPO+;
                                                           ZGH_PRODUT+;
                                                           ZGH_CFOP+;
                                                           ZGH_TPMOV+;
                                                           ZGH_NATURE+;
                                                           ZGH_TIPOPD)})) # 0
   
       _nRepet+=2
        
        _aCols[_nPos2,1]:=.F.
        If (cAliasWK)->ZGH_CONTA # _aCols[_nPos2,3] //_aDupli[_nPos,2] 
           //Atualiza _aCols Anterior
           _aCols[_nPos2,nPosChave-1]:="[Chave repetida] [Com Conta diferente ("+AllTrim((cAliasWK)->ZGH_CONTA)+")] "
           //Atualiza _aCols Atual
           _cMsg:="[Chave repetida] [Com Conta diferente ("+_aCols[_nPos2,3]+")] "//_aDupli[_nPos,2]
        Else
           //Atualiza _aCols Anterior
           _aCols[_nPos2,nPosChave-1]:="[Chave repetida 1] "
           //Atualiza _aCols Atual
           _cMsg:="[Chave repetida 2] "
        EndIf
        _nRecWKSalva:=(cAliasWK)->(RECNO())
        //Atualiza cAliasWK Anterior
        (cAliasWK)->(DBGoTo(_aCols[_nPos2,nPosChave+1]))
        (cAliasWK)->WK_MARCA:=.F.
        (cAliasWK)->WK_MSG  :=_aCols[_nPos2,nPosChave-1]
         //Atualiza cAliasWK Atual
        (cAliasWK)->(DBGoTo(_nRecWKSalva))
        (cAliasWK)->WK_MARCA:=.F.
        (cAliasWK)->WK_MSG  :=_cMsg

   Else

      (cAliasWK)->WK_MARCA:=.T.
      _cMsg:=""

   EndIf

   aAdd(_aCols,{(cAliasWK)->WK_MARCA,; //01
                ZGH_FILIAL,;           //02
                (cAliasWK)->ZGH_CONTA,;//03
                ZGH_CLIENT,;           //04
                ZGH_CLILOJ,;           //05
                ZGH_FORNER,;           //06
                ZGH_FORLOJ,;           //07
                ZGH_PRODUT,;           //08
                ZGH_GRUPO,;            //09
                ZGH_CFOP,;             //10
                ZGH_TPMOV,;            //11
                ZGH_NATURE,;           //12
                ZGH_TIPOPD,;           //13
                _cMsg,;                //14
                (cAliasWK)->(ZGH_FILIAL+ZGH_CLIENT+ZGH_CLILOJ+ZGH_FORNER+ZGH_FORLOJ+ZGH_GRUPO+ZGH_PRODUT+ZGH_CFOP+ZGH_TPMOV+ZGH_NATURE+ZGH_TIPOPD),;//15 - chave completa
                (cAliasWK)->(RECNO()) })//16
  
  (cAliasAux)->(DBSkip())

EndDo

_cTitAux:='REGRAS SPEED 500 - HrI: '+_cTimeIni+" / HrF: "+TIME()+" / Total: "+_cTot+" / Repetidos: "+StrZero(_nRepet,7)+" / Arq.: "+cNomArq

If Len(_aCols) # 0 .And. !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
   oproc:cCaption := _cTitAux
   _AHEADER:={" ",'FILIAL','CONTA','COD. CLIENTE','LOJA','COD, FORN','LOJA','PRODUTO','GRUPO','CFOP','TIPO','NATUREZA','TP PROD','OBSERVACAO',"CHAVE"}
   DlgToExcel( { { "ARRAY" , _cTitAux , _aHeader , _aCols } } )//já gera pq caso que pode cair
EndIf

If Select(cAliasAux) > 0
   (cAliasAux)->(DBCloseArea())
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: AFIS008Ape
Autor-------------: Alex Wallauer
Data da Criacao---: 27/02/2020
Descrição---------: Processamento de Importação de DADOS DO TYT
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIS008Ape(oProc)

oProc:cCaption := ("Lendo dados de devoluções...")
ProcessMessages()
  
   
_cArq := AllTrim(_cFileCSV)
If Upper(RIGHT(_cArq,3)) <> "CSV" .Or. FT_FUSE(_cArq) == -1
	U_ITMsg("Não foi possível abrir o arquivo informado.",;
	"Arquivo inválido","O arquivo informado deve ser .CSV ou verificar se o arquivo informado esta correto.",1)
	Return .F.
EndIf


FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
_cDados := FT_FREADLN()
	
If ! "FILIAL;CONT CONTABI;COD. CLIENTE;LOJ CLIENTE;COD. FORNECE;LOJ FORNCEDO;PRODUTO;GRUPO;CFOP;TIPO MOVIMEN;COD. NATUREZ;TIPO PROD." $ Upper(AllTrim(_cDados))
	U_ITMsg("Arquivo informado com o cabeçalho incorreto.",;
            "Arquivo inválido","O arquivo deve conter o cabeçalho: Filial;Cont Contabi;Cod. Cliente;Loj Cliente;Cod. Fornece;Loj Forncedo;Produto;Grupo;CFOP;Tipo Movimen;Cod. Naturez;Tipo Prod.",1)
	Return .F.
EndIf
	
_cTot:=FT_FLASTREC()-1
_cTot:=AllTrim(Str(_cTot))
_nTam:=Len(_cTot)
_nCont:=_nConta:=0

_aLinRepetido={}
SB1->(DBSetOrder(1))
DA1->(DBSetOrder(1))
SA1->(DBSetOrder(1))

FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
FT_FSKIP()//PULA OS TITULOS
 	
While !FT_FEOF()  //FACA ENQUANTO NAO For FIM DE ARQUIVO
 	
	_nCont++
	oProc:cCaption := ("Processando Dados: "+ StrZero(_nCont,_nTam) +" de "+ _cTot)
	ProcessMessages()
	
	_cDados := AllTrim(FT_FREADLN())
	_cDados := StrTran(_cDados,'"','')//Tem que ter ate 6 colunas
	_cDados := StrTran(_cDados,',','.')//Campos com decimais
	
	//Verifica se é final de arquivo
	If Empty(AllTrim(_cDados)) .Or. AllTrim(_cDados) = ';;;;;;;;;;;;;' 
		Exit
	EndIf

    If aScan(_aLinRepetido,_cDados) = 0
        aAdd(_aLinRepetido,_cDados)    
    Else
       FT_FSKIP()
       Loop
    EndIf
  	
	_aLinhas:= StrTokArr2(_cDados,";",.T.)

	If Empty(Val(_aLinhas[01])) 
       FT_FSKIP()
       Loop
	EndIf
	
    If(Len(_aLinhas) > 00,(cAliasWK)->(DBAPPEND())              ,)
	If(Len(_aLinhas) > 00,(cAliasWK)->ZGH_FILIAL := StrZero(Val(_aLinhas[01]),2),)
	If(Len(_aLinhas) > 01,(cAliasWK)->ZGH_CONTA  := _aLinhas[02],)
	If(Len(_aLinhas) > 02,(cAliasWK)->ZGH_CLIENT := _aLinhas[03],)
	If(Len(_aLinhas) > 03,(cAliasWK)->ZGH_CLILOJ := _aLinhas[04],)
	If(Len(_aLinhas) > 04,(cAliasWK)->ZGH_FORNER := _aLinhas[05],)
	If(Len(_aLinhas) > 05,(cAliasWK)->ZGH_FORLOJ := _aLinhas[06],)
	If(Len(_aLinhas) > 06,(cAliasWK)->ZGH_PRODUT := _aLinhas[07],)
	If(Len(_aLinhas) > 07,(cAliasWK)->ZGH_GRUPO  := _aLinhas[08],)
	If(Len(_aLinhas) > 08,(cAliasWK)->ZGH_CFOP   := _aLinhas[09],)
	If(Len(_aLinhas) > 09,(cAliasWK)->ZGH_TPMOV  := _aLinhas[10],)
	If(Len(_aLinhas) > 10,(cAliasWK)->ZGH_NATURE := _aLinhas[11],)
	If(Len(_aLinhas) > 11,(cAliasWK)->ZGH_TIPOPD := _aLinhas[12],)

    FT_FSKIP()

EndDo

FT_FUSE()

Return .T.	

/*
===============================================================================================================================
Programa----------: AFIS008Grv()
Autor-------------: Alex Wallauer
Data da Criacao---: 27/12/2017
Descrição---------: Grava os dados lidos do CSV
Parametros--------: oproc,_lAnalizar
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIS008Grv(oproc,_lAnalizar)

Local _nConta:=_nCont2:=0//,_nQbg:=250
Local _cTimeIni:=Time()
_aCols:={}

_nConta:=(cAliasWK)->(LASTREC())
_cTot:=AllTrim(Str(_nConta))
_nConta:=0
_nRepet:=0
oproc:cCaption := "Gravando, Aguarde... Hora Inicial :"+_cTimeIni
ProcessMessages()
ZGH->(DBSetOrder(3))//ZGH_FILIAL+ZGH_CLIENT+ZGH_CLILOJ+ZGH_FORNER+ZGH_FORLOJ+ZGH_GRUPO+ZGH_PRODUT+ZGH_CFOP+ZGH_TPMOV
DBSelectArea( cAliasWK )
(cAliasWK)->(DBGoTop())
While (cAliasWK)->(!Eof())
    _nConta++
    oproc:cCaption := "HI: "+_cTimeIni+" - Gravando Regra: "+StrZero(_nConta,6)+" / "+_cTot+" - "+StrZero(_nRepet,7)//+" / Arq.: "+cNomArq
    ProcessMessages()
  
   If !Empty((cAliasWK)->WK_MSG) //.OR. !(cAliasWK)->WK_MARCA 
      _nRepet++
      aAdd(_aCols,{(cAliasWK)->WK_MARCA,ZGH_FILIAL,ZGH_CONTA,ZGH_CLIENT,ZGH_CLILOJ,ZGH_FORNER,ZGH_FORLOJ,ZGH_PRODUT,ZGH_GRUPO,ZGH_CFOP,ZGH_TPMOV,ZGH_TIPOPD,;
                   (cAliasWK)->WK_MSG,"IGNORADO" })
      (cAliasWK)->(DBSkip())
      Loop
   EndIf
   _lGrava:=.F.
   If !Empty((cAliasWK)->ZGH_NATURE) 
      ZGH->(DBSetOrder(4))//ZGH_FILIAL+ZGH_NATURE
	  If !ZGH->(DBSeek(xFilial("ZGH")+(cAliasWK)->ZGH_NATURE ))
         _lGrava:=.T.
      EndIf
   ElseIf !Empty((cAliasWK)->ZGH_TIPOPD) 
      ZGH->(DBSetOrder(6))//ZGH_FILIAL+ZGH_TIPOPD
      If !ZGH->(DBSeek((cAliasWK)->(ZGH_FILIAL+ZGH_TIPOPD)))
         _lGrava:=.T.
      EndIf
   Else
      ZGH->(DBSetOrder(3))//ZGH_FILIAL+ZGH_CLIENT+ZGH_CLILOJ+ZGH_FORNER+ZGH_FORLOJ+ZGH_GRUPO+ZGH_PRODUT+ZGH_CFOP+ZGH_TPMOV
      If !ZGH->(DBSeek((cAliasWK)->(ZGH_FILIAL+ZGH_CLIENT+ZGH_CLILOJ+ZGH_FORNER+ZGH_FORLOJ+ZGH_GRUPO+ZGH_PRODUT+ZGH_CFOP+ZGH_TPMOV)))
         _lGrava:=.T.
      EndIf
   EndIf

   If _lGrava
      _nCont2++
      If !_lAnalizar
         ZGH->(RecLock("ZGH",.T.))
         AVREPLACE(cAliasWK,"ZGH")
         ZGH->ZGH_FILIAL:=(cAliasWK)->ZGH_FILIAL
         ZGH->(MSUnLock())
         _cMsg:="[Cadastrado com sucesso]"
      Else
         _cMsg:="[Regra OK]"
      EndIf   

      aAdd(_aCols,{.T.,ZGH_FILIAL,ZGH_CONTA,ZGH_CLIENT,ZGH_CLILOJ,ZGH_FORNER,ZGH_FORLOJ,ZGH_PRODUT,ZGH_GRUPO,ZGH_CFOP,ZGH_TPMOV,ZGH_NATURE,ZGH_TIPOPD,;
                   _cMsg,(cAliasWK)->WK_MSG})
   Else
      _nRepet++
      _cMsg:="[Já cadastrado no sistema] "+If( (cAliasWK)->ZGH_CONTA # ZGH->ZGH_CONTA,"[Com Conta diferente ("+ZGH->ZGH_CONTA+")] "," ") 
      aAdd(_aCols,{.F.,ZGH_FILIAL,ZGH_CONTA,ZGH_CLIENT,ZGH_CLILOJ,ZGH_FORNER,ZGH_FORLOJ,ZGH_PRODUT,ZGH_GRUPO,ZGH_CFOP,ZGH_TPMOV,ZGH_NATURE,ZGH_TIPOPD,;
                   _cMsg,(cAliasWK)->WK_MSG})
   EndIf

   (cAliasWK)->(DBSkip())

EndDo

If Len(_aCols) > 0

   If _lAnalizar
      _cTitAux:='INTEGRAÇÃO DE REGRAS SPEED 500 - HrI: '+_cTimeIni+" / HrF: "+TIME()+" / Foram analizados "+_cTot+" / já cadastros: "+StrZero(_nRepet,7)+" / Arq.: "+cNomArq
   Else  
      _cTitAux:='INTEGRAÇÃO DE REGRAS SPEED 500 - HrI: '+_cTimeIni+" / HrF: "+TIME()+" / Foram gravadas "+AllTrim(Str(_nCont2))+" de "+_cTot+" / já cadastros: "+StrZero(_nRepet,7)+" / Arq.: "+cNomArq
   EndIf  
   _AHEADER:={" ",'FILIAL','CONTA','COD. CLIENTE','LOJA','COD, FORN','LOJA','PRODUTO','GRUPO','CFOP','TIPO','NATUREZA','TP PROD','OBSERVACAO1','OBSERVACAO2'}
   _ASIZES :={ 10,      30,     40,            40,    30,         40,    30,      50,      40,    40,    30,        50,       30,         200,          100}
  
   //ITLISTBOX( _CTITAUX,_AHEADER , _ACOLS,_LMAXSIZ,_NTIPO,_CMSGTOP , _LSELUNC , _ASIZES , _NCAMPO , BOK , BCANCEL )
   U_ITLISTBOX( _cTitAux,_AHEADER , _aCols, .T.    , 4    ,         ,          ,_ASIZES  , )

Else

   If !_lAnalizar
      U_ITMsg("Foram gravadas "+AllTrim(Str(_nCont2))+" de "+_cTot+" Regras. HrI: "+_cTimeIni+" / HrF: "+TIME()+" / Arq.: "+cNomArq,'Atenção!',,2)
   Else   
      U_ITMsg("TUDO OK",'Atenção!',,2)
   EndIf

EndIf

Return .T.
