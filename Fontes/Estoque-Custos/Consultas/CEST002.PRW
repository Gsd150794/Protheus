/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |12/06/2019| Chamado 29593. Ajustes para loboguara
Alex Wallauer |06/11/2019| Chamado 28346. Revisão de fonte para novo appserver
Lucas Borges  |09/05/2025| Chamado 50617. Corrigir chamada estática no nome das tabelas do sistema
===============================================================================================================================
*/

#Include "FWMVCDEF.CH"
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: CEST002
Autor-------------: Josué Danich Prestes
Data da Criacao---: 15-04-2015
Descrição---------: Consultar e simular custos, precos e margens
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function CEST002()

Local _aStru 		:= {}
Local _cQry 		:= ''

If !MSGYESNO("Deseja iniciar a leitura dos dados para a analise gerencial?")
   Return .T.
EndIf

//Log de utilização
U_ITLOGACS()

Private cAlias:= GetNextAlias()
Private _aCpos := {}

//criar estrutura de arquivo temporario
aAdd(_aStru,{"MESANO"	,"C",8,0})
aAdd(_aStru,{"COMPOR"	,"C",8,0})
aAdd(_aStru,{"PRODUTO"	,"C",TamSX3("B1_COD")[1],TamSX3("B1_COD")[2]})
aAdd(_aStru,{"DESCR"   	,"C",TamSX3("B1_DESC")[1],TamSX3("B1_DESC")[2]})
aAdd(_aStru,{"CUSTO"	,"N",18,7})
aAdd(_aStru,{"CUSTOO"	,"N",18,7})
aAdd(_aStru,{"CUSTOP"	,"N",18,7})
aAdd(_aStru,{"PRCMIN"	,"N",18,7})
aAdd(_aStru,{"PRCMED"	,"N",18,7})
aAdd(_aStru,{"PRECOR"	,"N",18,7})
aAdd(_aStru,{"PRCMAX"	,"N",18,7})
aAdd(_aStru,{"MRGP"		,"N",18,7})
aAdd(_aStru,{"MRG"		,"N",18,7})
aAdd(_aStru,{"QTDPRO"	,"N",18,7})
aAdd(_aStru,{"QTDFAT"	,"N",18,7})
aAdd(_aStru,{"FATURA"	,"N",18,7})
aAdd(_aStru,{"CUSTOE"	,"N",18,7})
aAdd(_aStru,{"CUSTOF"	,"N",18,7})
aAdd(_aStru,{"CUSTOI"	,"N",18,7})
aAdd(_aStru,{"CUSTOU"	,"N",18,7})
aAdd(_aStru,{"CUSTOL"	,"N",18,7})
aAdd(_aStru,{"REAJL"    ,"N",18,7})
aAdd(_aStru,{"REJCC"    ,"N",18,7})
aAdd(_aStru,{"REJVBA"   ,"N",18,7})
aAdd(_aStru,{"REJIMP"   ,"N",18,7})
aAdd(_aStru,{"REAJE"	,"N",18,7})
aAdd(_aStru,{"REAJI"	,"N",18,7})
aAdd(_aStru,{"REAJF"	,"N",18,7})
aAdd(_aStru,{"REAJU"	,"N",18,7})
aAdd(_aStru,{"REAJO"	,"N",18,7})
aAdd(_aStru,{"GRUPO"	,"C",30,0})
aAdd(_aStru,{"MARGEM"	,"N",18,7})


_otemp := FWTemporaryTable():New( "ZTRB", _aStru )

_otemp:AddIndex( "01", {"MESANO"} )
_otemp:AddIndex( "02", {"GRUPO"} )
_otemp:AddIndex( "03", {"PRODUTO"} )
_otemp:AddIndex( "04", {"DESCR"} )

_otemp:Create()

//consultar os dados 
_cQry += " SELECT ZE1_PRODUT, "
_cQry += "        ZE1_PRCMIN, "
_cQry += "        ZE1_PRCMAX, "
_cQry += "        ZE1_CUSTOP, "
_cQry += "        ZE1_FATURA, "
_cQry += "        ZE1_QTDFAT, "
_cQry += "        ZE1_QTDPRO, "
_cQry += "        ZE1_COMP,   "
_cQry += "        ZE1_CUSTOO, "
_cQry += "        ZE1_CUSTOE, "
_cQry += "        ZE1_CUSTOF, "
_cQry += "        ZE1_CUSTOI, "
_cQry += "        ZE1_CUSTOU, "
_cQry += "        ZE1_REAJL,  "
_cQry += "        ZE1_REAJE,  "
_cQry += "        ZE1_REAJI,  "
_cQry += "        ZE1_REAJF,  "
_cQry += "        ZE1_MARGEM,  "
_cQry += "        ZE1_REJCC,  "
_cQry += "        ZE1_REJIMP,  "
_cQry += "        ZE1_REJVBA,  "
_cQry += "        ZE1_REAJU,  "
_cQry += "        ZE1_REAJO,  "
_cQry += "        ZE1_COMPOR,  "
_cQry += "        ZE1_PRECOR,  "
_cQry += "        ZE1_GRUPO,  "
_cQry += "        ZE1_CUSTOL "

_cQry += " FROM " + RetSqlname("ZE1") + " ZE1 " 

_cQry += " WHERE  ZE1.D_E_L_E_T_ = ' '"
_cQry += "        AND ( ZE1_CUSTOP > 0 OR ZE1_COMP = 'ATUAL' ) "
_cQry += "        AND ZE1_FILIAL = '" + xFilial("ZE1") + "'"

_cQry := ChangeQuery(_cQry)
MPSysOpenQuery(_cQry,cAlias)

Processa( {|| CEST002A() },,"Filtrando registros...")

If Select(cAlias) > 0 
   cAlias->(DBCloseArea())
EndIf

If Select("ZTRB") > 0 
   ZTRB->(E_EraseArq(cFile,cFile2,cFile3))
EndIf

Return

/*
===============================================================================================================================
Programa----------: CEST002A
Autor-------------: Josue Danich Prestes
Data da Criacao---: 07/01/2016
Descrição---------: Filtrando dados para apresentação da planilha
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CEST002A()

Local _aCpos 		:= {}
Local _aAreaSM0 	:= SM0->(GetArea())
Local _ncustopr	:= 0
Local _ncustoop	:= 0

Private _bbloco	:= { || U_CEST002R(),_oBrw:Refresh(),  }
Private _bbloco2:= { || U_CEST002V(),_oBrw:Refresh(),  }
Private _bbloco3:= { || U_CEST002P(),_oBrw:Refresh(),  }
Private aRotina := {}
Private _oBrw	:= FWMBrowse():New()


//atualizar arquivo de trabalho
(cAlias)->(DBGoTop())

DBSelectArea(cAlias)
count to nTot

ZTRB->( DBSetOrder(2) )

ProcRegua( nTot )
(cAlias)->(DBGoTop())

While (cAlias)->(!Eof())
	
	IncProc("Processando produto "+AllTrim((cAlias)->ZE1_PRODUT))
	ZTRB->(DBAPPEND())
		
	If 	AllTrim((cAlias)->ZE1_COMP) == "ATUAL" //LE VALORES COM REAJUSTES
	 
		ZTRB->MESANO 	:= "ATUAL" 
		_ncustoop		:=	(cAlias)->ZE1_CUSTOO + ( (cAlias)->ZE1_CUSTOO * (cAlias)->ZE1_REAJO / 100 ) 
		
		_ncustopr 		:=  (cAlias)->ZE1_CUSTOP
		
		
		ZTRB->CUSTO	    := (_ncustopr + _ncustoop + (cAlias)->ZE1_REJCC + (cAlias)->ZE1_REJIMP + (cAlias)->ZE1_REJVBA) / (cAlias)->ZE1_QTDPRO
		ZTRB->CUSTOP	:= (_ncustopr)
		ZTRB->CUSTOO	:= (_ncustoop)
		ZTRB->COMPOR	:= (cAlias)->ZE1_COMPOR
		
		If (cAlias)->ZE1_PRECOR > 0
		
			ZTRB->PRCMED 	:= (cAlias)->ZE1_PRECOR
			ZTRB->PRECOR	:= (cAlias)->ZE1_PRECOR
			ZTRB->PRCMIN	:= 0
			ZTRB->PRCMAX	:= 0
			ZTRB->MRGP		:= (((((cAlias)->ZE1_QTDPRO * ZTRB->PRECOR) - ((cAlias)->ZE1_CUSTOP + (cAlias)->ZE1_CUSTOO)))/((cAlias)->ZE1_QTDPRO * ZTRB->PRECOR))*100 
			ZTRB->MARGEM	:= (cAlias)->ZE1_MARGEM
		
		Else
		
			ZTRB->PRCMED	:= Round(((cAlias)->ZE1_FATURA / (cAlias)->ZE1_QTDFAT),2)
			ZTRB->PRCMIN	:= 0
			ZTRB->PRCMAX	:= 0
			ZTRB->MRGP		:=	Round((((((cAlias)->ZE1_QTDPRO * ZTRB->PRCMED) - ((cAlias)->ZE1_CUSTOP + (cAlias)->ZE1_CUSTOO)))/((cAlias)->ZE1_QTDPRO * ZTRB->PRCMED))*100 ,2)
			ZTRB->MARGEM	:= (cAlias)->ZE1_MARGEM
					
		EndIf
	
	Else
	
		ZTRB->MESANO	:= SubStr(AllTrim((cAlias)->ZE1_COMP),1,2) + "/" + SubStr(AllTrim((cAlias)->ZE1_COMP),3,4) 
		ZTRB->CUSTO	    := ((cAlias)->ZE1_CUSTOP + (cAlias)->ZE1_CUSTOO+(cAlias)->ZE1_REJCC+(cAlias)->ZE1_REJIMP+(cAlias)->ZE1_REJVBA) / (cAlias)->ZE1_QTDPRO
		ZTRB->CUSTOP	:= (cAlias)->ZE1_CUSTOP
		_ncustopr 		:= (cAlias)->ZE1_CUSTOP
		ZTRB->CUSTOO	:= (cAlias)->ZE1_CUSTOO
		_ncustoop		:= (cAlias)->ZE1_CUSTOO
		ZTRB->PRCMED	:= Round(((cAlias)->ZE1_FATURA / (cAlias)->ZE1_QTDFAT),2)
		ZTRB->PRCMIN	:= (cAlias)->ZE1_PRCMIN
		ZTRB->PRCMAX	:= (cAlias)->ZE1_PRCMAX
		ZTRB->MRGP		:= Round((((((cAlias)->ZE1_QTDPRO * ZTRB->PRCMED) - ((cAlias)->ZE1_CUSTOP + (cAlias)->ZE1_CUSTOO)))/((cAlias)->ZE1_QTDPRO * ZTRB->PRCMED))*100 ,2)
		ZTRB->MRG		:= Round((((cAlias)->ZE1_QTDPRO * ZTRB->PRCMED) - ((cAlias)->ZE1_CUSTOP + (cAlias)->ZE1_CUSTOO)) ,2)
		ZTRB->MARGEM	:= (cAlias)->ZE1_MARGEM
	
	EndIf
	
	ZTRB->PRODUTO   := AllTrim((cAlias)->ZE1_PRODUT)
	ZTRB->DESCR      := AllTrim(Posicione("SB1",1,xFilial("SB1")+(cAlias)->ZE1_PRODUT,"B1_DESC"))
	ZTRB->QTDPRO	:= (cAlias)->ZE1_QTDPRO
	ZTRB->QTDFAT	:= (cAlias)->ZE1_QTDFAT
	ZTRB->FATURA	:= (cAlias)->ZE1_FATURA
	ZTRB->CUSTOE	:= (cAlias)->ZE1_CUSTOE 
	ZTRB->CUSTOF	:= (cAlias)->ZE1_CUSTOF 
	ZTRB->CUSTOI	:= (cAlias)->ZE1_CUSTOI 
	ZTRB->CUSTOU	:= (cAlias)->ZE1_CUSTOU 
	ZTRB->CUSTOL	:= (cAlias)->ZE1_CUSTOL 
	ZTRB->REAJL	    := (cAlias)->ZE1_REAJL
	ZTRB->REAJE	    := (cAlias)->ZE1_REAJE
	ZTRB->REAJI	    := (cAlias)->ZE1_REAJI
	ZTRB->REAJF	    := (cAlias)->ZE1_REAJF
	ZTRB->REAJU 	:= (cAlias)->ZE1_REAJU
	ZTRB->REAJO  	:= (cAlias)->ZE1_REAJO
	ZTRB->REJCC	    := (cAlias)->ZE1_REJCC
	ZTRB->REJIMP	:= (cAlias)->ZE1_REJIMP
	ZTRB->REJVBA	:= (cAlias)->ZE1_REJVBA
	ZTRB->GRUPO	    := (cAlias)->ZE1_GRUPO

	(cAlias)->(DBSkip())
	
EndDo 

(cAlias)->(DBCloseArea())

ZTRB->( DBGoTop() )
_oBrw:Refresh()

//Se não existir nenhum registro para a filial oferece a opção de gerar pelo cadastro
If ZTRB->( Eof() )
	If MessageBox("Não existem registros, gera a partir do cadastro de produtos?","Alerta!", 49) == 2
		Return
	Else
		CEST002G( nil, "CADASTRO PROD.")	
	EndIf
EndIf

//refazer os campos que apareceram no browse
_aCpos := {;
{"Mes/Ano" 	    ,"MESANO" 		,"C","@!"							,2,08,0},;	
{"Grupo" 		,"GRUPO" 		,"C","@!"	                        ,1,15,0},;
{"Produto" 	    ,"PRODUTO" 	    ,"C",PesqPict("SB1","B1_COD")	    ,2,TamSX3("B1_COD")[1],TamSX3("B1_COD")[2]},;
{"Descricao" 	,"DESCR" 		,"C",PesqPict("SB1","B1_DESC")	    ,1,20,0},;
{"Custo Unit"   ,"CUSTO" 		,"N","@E 999,999,999.99"			,18,7,0},;	
{"Preco Min" 	,"PRCMIN" 		,"N","@E 999,999,999.99"			,18,7,0},;	
{"Preco Med" 	,"PRCMED" 		,"N","@E 999,999,999.99"			,18,7,0},;	
{"Preco Max" 	,"PRCMAX" 		,"N","@E 999,999,999.99"			,18,7,0},;	
{"% Margem" 	,"MRGP" 		,"N","@E 999,999,999.99"		    ,18,7,0},;
{"Margem" 		,"MARGEM" 		,"N","@E 999,999,999.99"			,18,7,0}}

FWRestArea(_aAreaSM0)

//apresentar a planilha de registros
ZTRB->(DBGoTop())

//Instaciamento de duplo clique e filtro
_oBrw:bldblclick        := {|| CEST002C() }
_oBrw:SetUseFilter(.T.)   
_oBrw:SetUseCaseFilter(.T.)

//tabela que será utilizada
_oBrw:SetAlias( "ZTRB" )

//Titulo
_oBrw:SetDescription( "Custo, Precos e Margens" )

//seta as colunas para o browse
_oBrw:SetFields(_aCpos)

_apesq  := {}
_apesq2 := {}

aAdd(_apesq,"Grupo")
aAdd(_apesq,{{"     " ,"C",TamSX3("B1_COD")[1],TamSX3("B1_COD")[2],"Grupo + Código Produto",PesqPict("SB1","B1_COD"),"GRUPO + PRODUTO"}})
aAdd(_apesq,1)
aAdd(_apesq,.T.)
aAdd(_apesq2,_apesq)
_apesq := {}

aAdd(_apesq,"MesAno")
aAdd(_apesq,{{"     " ,"C",TamSX3("B1_DESC")[1],TamSX3("B1_DESC")[2],"Descrição",PesqPict("SB1","B1_DESC"),"DESCR"}})
aAdd(_apesq,2)
aAdd(_apesq,.T.)

aAdd(_apesq2,_apesq)
_apesq := {}

aAdd(_apesq,"Produto")
aAdd(_apesq,{{"     " ,"C",TamSX3("B1_COD")[1],TamSX3("B1_COD")[2],"Grupo + Código Produto",PesqPict("SB1","B1_COD"),"GRUPO + PRODUTO"}})
aAdd(_apesq,4)
aAdd(_apesq,.T.)

aAdd(_apesq2,_apesq)
_apesq := {}

aAdd(_apesq,"Descricao")
aAdd(_apesq,{{"     " ,"C",TamSX3("B1_COD")[1],TamSX3("B1_COD")[2],"Grupo + Código Produto",PesqPict("SB1","B1_COD"),"GRUPO + PRODUTO"}})
aAdd(_apesq,3)
aAdd(_apesq,.T.)

aAdd(_apesq2,_apesq)
_apesq := {}

_oBrw:SetSeek(.T.,_apesq2)

//define as legendas
_oBrw:AddLegend('MESANO = "ATUAL" ',"BR_AMARELO" ,"Simulacao")
_oBrw:AddLegend('MRGP > 0 ',"BR_VERDE" ,"Margem Positiva")
_oBrw:AddLegend('MRGP < 0 .Or. MRGP == 0 ',"BR_VERMELHO","Margem total zerada ou negativa")

//Desabilita tela de detalhes e walthru e ambiente
_oBrw:SetWalkThru(.F.)
_oBrw:SetAmbiente(.F.)
_oBrw:DisableDetails()

//botão
ADD OPTION aRotina Title 'Reajusta dados atuais'   Action 'Eval(_bbloco2)'		OPERATION 3 ACCESS 0
ADD OPTION aRotina Title 'Gera Tabela de Precos'   Action 'Eval(_bbloco3)'		OPERATION 1 ACCESS 0
ADD OPTION aRotina Title 'Refaz dados atuais'	   Action 'Eval(_bbloco)'		OPERATION 2 ACCESS 0
ADD OPTION aRotina Title "Legenda"    	           Action 'U_CEST002L()'		OPERATION 4 ACCESS 0

//ativa
_oBrw:Activate()

Return

/*
===============================================================================================================================
Programa----------: CEST002L
Autor-------------: Alex Walaluer
Data da Criacao---: 06/06/2016
Descrição---------: Tela de Legenda
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function CEST002L()

Local _aCores := {	{ 'BR_VERDE'	, "Margem Positiva"		  		    },;
					{ 'BR_AMARELO'	, "Simulacao"	                    },;
					{ 'BR_VERMELHO'	, "Margem total zerada ou negativa"	} }

BrwLegenda('Legenda','Status',_aCores)

Return .T.
/*
===============================================================================================================================
Programa----------: CEST002C
Autor-------------: Josue Danich Prestes
Data da Criacao---: 07/01/2016
Descrição---------: Tela de análise de preços
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CEST002C()

Local _alist 		:= {}
Local _oDlg1 	:= nil
Local _oPanel 	:= nil
Local _nprod	:= IIf(ZTRB->QTDPRO > 0, ZTRB->QTDPRO, 1)
Local _nMargem	:= If( ZTRB->MARGEM # 0 .Or. ZTRB->PRCMED = 0, ZTRB->MARGEM , (ZTRB->PRCMED-ZTRB->CUSTO) )
Local _np00		:= ( (_nMargem*_nprod) / (ZTRB->PRCMED * _nprod)) * 100
Local _np01 	:= ((100 - _np00) * ZTRB->CUSTOP) / ( ZTRB->CUSTOP+ZTRB->CUSTOO+ZTRB->REJCC+ZTRB->REJIMP+ZTRB->REJVBA)
Local _np02		:= ((100 - _np00) * ZTRB->CUSTOO) / ( ZTRB->CUSTOP+ZTRB->CUSTOO+ZTRB->REJCC+ZTRB->REJIMP+ZTRB->REJVBA)
Local _np11		:= ((100 - _np00) * ZTRB->REJIMP) / ( ZTRB->CUSTOP+ZTRB->CUSTOO+ZTRB->REJCC+ZTRB->REJIMP+ZTRB->REJVBA)
Local _np12		:= ((100 - _np00) * ZTRB->REJVBA) / ( ZTRB->CUSTOP+ZTRB->CUSTOO+ZTRB->REJCC+ZTRB->REJIMP+ZTRB->REJVBA)
Local _np03		:= 100 - _np00
Local _np04		:= ((ZTRB->FATURA - ( ZTRB->CUSTOP+ZTRB->CUSTOO+ZTRB->REJCC+ZTRB->REJIMP+ZTRB->REJVBA ))  / ZTRB->FATURA) * 100
Local _np13		:= ((Round((ZTRB->FATURA / ZTRB->QTDFAT),2)*_nprod) - ( ZTRB->CUSTOP+ZTRB->CUSTOO+ZTRB->REJCC+ZTRB->REJIMP+ZTRB->REJVBA ))  / (Round((ZTRB->FATURA / ZTRB->QTDFAT),2)*_nprod) * 100
Local _np05		:= ((100 - _np00) * ZTRB->CUSTOL) / ( ZTRB->CUSTOP+ZTRB->CUSTOO+ZTRB->REJCC+ZTRB->REJIMP+ZTRB->REJVBA)
Local _np06		:= ((100 - _np00) * ZTRB->CUSTOE) / ( ZTRB->CUSTOP+ZTRB->CUSTOO+ZTRB->REJCC+ZTRB->REJIMP+ZTRB->REJVBA)
Local _np07		:= ((100 - _np00) * ZTRB->CUSTOI) / ( ZTRB->CUSTOP+ZTRB->CUSTOO+ZTRB->REJCC+ZTRB->REJIMP+ZTRB->REJVBA)
Local _np08		:= ((100 - _np00) * ZTRB->CUSTOF) / ( ZTRB->CUSTOP+ZTRB->CUSTOO+ZTRB->REJCC+ZTRB->REJIMP+ZTRB->REJVBA)
Local _np09		:= ((100 - _np00) * ZTRB->CUSTOU) / ( ZTRB->CUSTOP+ZTRB->CUSTOO+ZTRB->REJCC+ZTRB->REJIMP+ZTRB->REJVBA)

Private _oBrowse	:= nil
Private aRotina	:= {}

//prepara margem e zera tudo se valor unitario For zero

//===================================================================================================
//prepara itens da janela de análise
//===================================================================================================
aAdd(_alist,{"Custo Producao"				,ZTRB->CUSTOP , ZTRB->CUSTOP/_nprod , _np01 , 0})			//01 CT
aAdd(_alist,{"      Leite/MP"				,ZTRB->CUSTOL , ZTRB->CUSTOL/_nprod , _np05 , ZTRB->REAJL})	//02
aAdd(_alist,{"      Embalagens"				,ZTRB->CUSTOE , ZTRB->CUSTOE/_nprod , _np06 , ZTRB->REAJE})	//03
aAdd(_alist,{"      Insumos"				,ZTRB->CUSTOI , ZTRB->CUSTOI/_nprod , _np07 , ZTRB->REAJI})	//04
aAdd(_alist,{"      Frete"		 		  	,ZTRB->CUSTOF , ZTRB->CUSTOF/_nprod , _np08 , ZTRB->REAJF})	//05
aAdd(_alist,{"      Outros"		 		  	,ZTRB->CUSTOU , ZTRB->CUSTOU/_nprod , _np09 , ZTRB->REAJU})	//06
aAdd(_alist,{" "								," ","  ","  ","  "," "})				  				//  
aAdd(_alist,{"Custo Operacional"			,ZTRB->CUSTOO , ZTRB->CUSTOO/_nprod , _np02 , ZTRB->REAJO})	//08 CT
aAdd(_alist,{" "								," ","  ","  ","  "," "})								//  
aAdd(_alist,{" "								," ","  ","  ","  "," "})								//  
aAdd(_alist,{"Verba "						,ZTRB->REJVBA* _nprod ,ZTRB->REJVBA , _np12 ,ZTRB->REJVBA}) //11 CT
aAdd(_alist,{"Impostos "					,ZTRB->REJIMP* _nprod ,ZTRB->REJIMP , _np11 ,ZTRB->REJIMP}) //12 CT
aAdd(_alist,{"Custo corporativo "			,ZTRB->REJCC * _nprod ,ZTRB->REJCC  , _np11 ,ZTRB->REJCC})	//13 CT
aAdd(_alist,{" "								," ","  ","  ","  "," "})								//  
aAdd(_alist,{"Custo Total"					,0                    ,0            , _np03 ,0})		    //15
aAdd(_alist,{" "								," ","  ","  ","  "," "})								//  
aAdd(_alist,{"Margem"						,_nMargem    * _nprod ,_nMargem     , _np00 ,0})            //17
aAdd(_alist,{" "								," ","  ","  ","  "," "})                               //
aAdd(_alist,{"Fat Potencial/Preco"			,ZTRB->PRCMED* _nprod ,ZTRB->PRCMED , 100  ,0})             //19
aAdd(_alist,{" "							," "          ," ","  "," "})                               //
aAdd(_alist,{"Total Qtde Produzido"		     ,ZTRB->QTDPRO," ","  "," "})                               //21
aAdd(_alist,{"Total Qtde Faturado"			 ,ZTRB->QTDFAT," ","  "," "})                               //22
aAdd(_alist,{"Faturado / Mrg Real / Mrg Orig",ZTRB->FATURA,ZTRB->FATURA/ZTRB->QTDFAT,_np04,_np13})      //23

//=====================================================================================================
//Se For competência ATUAL aplica reajustes
//=====================================================================================================
If AllTrim(ZTRB->MESANO) == "ATUAL"

	//Atualiza campo de valores do custo por partes
	
	_aList[2][2] :=	_aList[2][2] + ( _aList[2][5]  * ZTRB->QTDPRO) 
	_aList[2][3] :=	_aList[2][3] + _aList[2][5] 
	
	_aList[3][2] :=	_aList[3][2] + ( _aList[3][5]  * ZTRB->QTDPRO) 
	_aList[3][3] :=	_aList[3][3] + _aList[3][5] 
		
	_aList[4][2] :=	_aList[4][2] + ( _aList[4][5]  * ZTRB->QTDPRO) 
	_aList[4][3] :=	_aList[4][3] + _aList[4][5] 	
	_aList[5][2] :=	_aList[5][2] + (_aList[5][5]   * ZTRB->QTDPRO) 
	_aList[5][3] :=	_aList[5][3] + _aList[5][5]
	
	_aList[6][2] :=	_aList[6][2] + ( _aList[6][5]  * ZTRB->QTDPRO) 
	_aList[6][3] :=	_aList[6][3] + _aList[6][5]  
	                                        
	_aList[8][2] :=	_aList[8][2] + ( _aList[8][5]  * ZTRB->QTDPRO) 
	_aList[8][3] :=	_aList[8][3] + _aList[8][5] 
	
	//Atualiza campo de faturamento potencial e preco medio/sugerio
	If ZTRB->PRECOR > 0
		_aList[19][3] := ZTRB->PRECOR
	EndIf
	
	_aList[19][2] := _aList[19][3] * _nprod
	
	//Atualiza campos de valor de margem 
	_aList[17][2] :=  _nMargem * _nprod
	_aList[17][3] :=  _nMargem
	_aList[17][4] :=  (_aList[17][2] / ( _aList[19][3] * _nprod )) * 100
	
EndIf

//atualiza campos de "Custo de Producao" := Leite/MP" + Embalagens" +Insumos"  + Frete" + Outros"
_aList[1][2] := _aList[2][2] + _aList[3][2] + _aList[4][2] + _aList[5][2] + _aList[6][2]  //custo produção
_aList[1][3] := _aList[2][3] + _aList[3][3] + _aList[4][3] + _aList[5][3] + _aList[6][3]  //custo produção unitario

//atualiza campos de "Custo Total" := "Custo Producao" +"Custo Operacional"  + "Verba " +"Impostos " +"Custo corporativo "
_aList[15][2]	:= _aList[1][2] + _aList[8][2] + _aList[11][2] + _aList[12][2] + _aList[13][2]
_aList[15][3]	:= _aList[1][3] + _aList[8][3] + _aList[11][3] + _aList[12][3] + _aList[13][3]

//Atualiza campos de valor de margem 
_aList[17][3] :=  _aList[19][3] - _aList[15][3]
_aList[17][2] :=  _aList[17][3] * _nprod
_aList[17][4] :=  (_aList[17][2] / ( _aList[19][3] * _nprod )) * 100

//Atualiza campos de porcentagem de custos
_aList[15][4] := 100 - _aList[17][4]
_aList[1][4] := (_aList[15][4] * _aList[1][2])/_aList[15][2]
_aList[2][4] := (_aList[15][4] * _aList[2][2])/_aList[15][2]
_aList[3][4] := (_aList[15][4] * _aList[3][2])/_aList[15][2]
_aList[4][4] := (_aList[15][4] * _aList[4][2])/_aList[15][2]
_aList[5][4] := (_aList[15][4] * _aList[5][2])/_aList[15][2]
_aList[6][4] := (_aList[15][4] * _aList[6][2])/_aList[15][2]
_aList[8][4] := (_aList[15][4] * _aList[8][2])/_aList[15][2]


//===================================================================================================
//abre janela de análise	
//===================================================================================================
DEFINE MSDIALOG _oDlg1 TITLE OemToAnsi("Analise Custo x Precos") From 0,0 To 525, 850 OF oMainWnd PIXEL

//_oDlg1:lMaximized
_oPanel       := TPanel():New(0,0,'',_oDlg1,, .T., .T.,, ,160,20,.T.,.T. )
_oPanel:Align := CONTROL_ALIGN_TOP // Somente Interface MDI
	
@ 0.8 ,00.8 Say OemToAnsi("Produto:   " + AllTrim(ZTRB->PRODUTO) + " - " + Posicione("SB1",1,xFilial("SB1")+ ZTRB->PRODUTO,"B1_DESC" )) OF _oPanel


If AllTrim(ZTRB->MESANO) == "ATUAL"

   @ 0.8 ,30.8 Say OemToAnsi(AllTrim(ZTRB->MESANO) + " com origem na competência " + AllTrim(ZTRB->COMPOR)  ) OF _oPanel

Else

   @ 0.8 ,30.8 Say OemToAnsi("Competencia:   " + AllTrim(ZTRB->MESANO)  ) OF _oPanel

EndIf
	
_oBrowse := TCBrowse():New( 020 , 003, 422, 218,,; 
{"Item","Valor Total","Valor Unit","  % ", "Reajuste"},{150,60,60,60,10},_oDlg1,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )
	
_oBrowse:AddColumn(TCColumn():New("Item"   		,{ || _aList[_oBrowse:nAt,1] },"@!"       			,,,"LEFT"  ,100,.F.,.F.,,,,,)) 
_oBrowse:AddColumn(TCColumn():New("Valor Total" ,{ || _aList[_oBrowse:nAt,2] },"@E 999,999,999.99"	,,,"RIGHT" ,060,.F.,.F.,,,,,)) 
_oBrowse:AddColumn(TCColumn():New("Valor Unit." ,{ || _aList[_oBrowse:nAt,3] },"@E 999,999,999.99"	,,,"RIGHT" ,060,.F.,.F.,,,,,)) 
_oBrowse:AddColumn(TCColumn():New("   %" 		,{ || _aList[_oBrowse:nAt,4] },"@E 999,999,999.99"  ,,,"RIGHT" ,060,.F.,.F.,,,,,)) 		
_oBrowse:AddColumn(TCColumn():New("Reajuste"	,{ || _aList[_oBrowse:nAt,5] },"@E 999,999,999.99"  ,,,"RIGHT" ,060,.F.,.F.,,,,,)) 		

//===================================================================================================
// Seta o vetor a ser utilizado                                                                      
//===================================================================================================
_oBrowse:SetArray(_aList) 
  
//===================================================================================================
// Monta a linha a ser exibida no Browse                                                             
//===================================================================================================
_oBrowse:bLine := {||{ 	_aList[_oBrowse:nAt,01],;
						_aList[_oBrowse:nAt,02],; 
						_aList[_oBrowse:nAt,03],; 
						_aList[_oBrowse:nAt,04],;
						_aList[_oBrowse:nAt,05] } }
	
//===================================================================================================		
// Evento de DuploClick (leva para rotina de edição e atualização do browse)                                
_oBrowse:bLDblClick := {|| CEST002B(_aList,_oBrowse) }                                                
//===================================================================================================

_aPos := PosDlg(_oDlg1)
nLinha:=_aPos[3]-If((AllTrim(cVersao) = "12"),12,22)
_nCol :=_aPos[4]-50
_nCol1:=_nCol-70

//aAdd( _aButtons, {"Grava Reajuste", {|| CEST002N(_aList)}, "Gravando dados...", "Grava Reajuste" , {|| .T.}} )
@ nLinha,_nCol1 Button oButton PROMPT "Grava dados" SIZE 50,15 ACTION ( Processa( {|| CEST002N(_aList) },, "Grava Reajuste..." ) , _oDlg1:End()) Pixel 

If !AllTrim(ZTRB->MESANO) == "ATUAL"
	oButton:Disable()
EndIf

@ nLinha,_nCol Button "Cancela"      SIZE 40,15 ACTION ( _oDlg1:End() ) Pixel 
     	
ACTIVATE MSDIALOG _oDlg1 //ON INIT EnchoiceBar(_oDlg1,{||_oDlg1:End()},{||_oDlg1:End()},,_aButtons,,,,,,.F.) CENTERED

Return

/*
===============================================================================================================================
Programa----------: CEST002B
Autor-------------: Josue Danich Prestes
Data da Criacao---: 07/01/2016
Descrição---------: Atualiza dados da planilha de analise de precos
Parametros--------: 	_aList - array com dados do browse
						_oBrowse - objeto do browse de planilha de preços	
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CEST002B(_aList,_oBrowse)

Local _npos 	:= _oBrowse:nAt
Local _nori	:= 0
Local _nval	:= 0
Local _nprod	:= IIf(ZTRB->QTDPRO > 0, ZTRB->QTDPRO,1)
Local _nvalini := 0

//Reajustes
If  _aList[_oBrowse:nAt][1] == "      Leite/MP" 	.or.;
	_aList[_oBrowse:nAt][1] == "      Embalagens"	.or.;
	_aList[_oBrowse:nAt][1] == "      Insumos"	.or.;
	_aList[_oBrowse:nAt][1] == "      Frete"		.or.;
	_aList[_oBrowse:nAt][1] == "      Outros"		.or.;
	_aList[_oBrowse:nAt][1] == "Verba "			.or.;
	_aList[_oBrowse:nAt][1] == "Impostos "			.or.;
	_aList[_oBrowse:nAt][1] == "Custo corporativo " .or.;
	_aList[_oBrowse:nAt][1] == "Custo Operacional"	

	//Guarda valor original para fazer variação
	_nori := _aList[_npos][5]
	
	If ZTRB->COMPOR == 'CADASTRO'
		//Edita campo de valor unitário
		lEditCell(_aList,_oBrowse,"@E 999,999,999.999999",3)	
		
		_aList[_oBrowse:nAt][2] := _aList[_oBrowse:nAt][3] * _nprod
	Else
		If _oBrowse:ncolpos == 5
			//Edita campo de  reajuste
			lEditCell(_aList,_oBrowse,"@E 999,999,999.999999",5)
		ElseIf _oBrowse:ncolpos == 3
		
			//guarda valor inicial
			_nvalini := _aList[_oBrowse:nAt][3]
			
			//Edita campo de  valor UNITARIO
			lEditCell(_aList,_oBrowse,"@E 999,999,999.999999",3)
			
			//arruma para ser como se tivesse editado o campo de reajuste
			_aList[_oBrowse:nAt][5] := _aList[_oBrowse:nAt][5] + ( _aList[_oBrowse:nAt][3] - _nvalini )
			_aList[_oBrowse:nAt][3] := _nvalini
			
		EndIf
	
	EndIf
	
	_oBrowse:DrawSelect()
	_oBrowse:gotop()
	_oBrowse:GoPosition(_npos)
	
	If _npos == 2
	
		_nval := IIf(ZTRB->COMPOR == 'CADASTRO', _aList[_oBrowse:nAt][2], ZTRB->CUSTOL)
		
	ElseIf _npos == 3
	
		_nval := IIf(ZTRB->COMPOR == 'CADASTRO', _aList[_oBrowse:nAt][2],ZTRB->CUSTOE)
			
	ElseIf _npos == 4
	
		_nval := IIf(ZTRB->COMPOR == 'CADASTRO', _aList[_oBrowse:nAt][2],ZTRB->CUSTOI)
			
	ElseIf _npos == 5
	
		_nval := IIf(ZTRB->COMPOR == 'CADASTRO', _aList[_oBrowse:nAt][2],ZTRB->CUSTOF)
			
	ElseIf _npos == 6
	
		_nval := IIf(ZTRB->COMPOR == 'CADASTRO', _aList[_oBrowse:nAt][2],ZTRB->CUSTOU)
	
	ElseIf _npos == 11
	
		_nval := IIf(ZTRB->COMPOR == 'CADASTRO', _aList[_oBrowse:nAt][2],ZTRB->REJCC)
		
	ElseIf _npos == 12
	
		_nval := IIf(ZTRB->COMPOR == 'CADASTRO', _aList[_oBrowse:nAt][2],ZTRB->REJIMP)
		
	ElseIf _npos == 13
	
		_nval := IIf(ZTRB->COMPOR == 'CADASTRO', _aList[_oBrowse:nAt][2],ZTRB->REJVBA)	
			
	ElseIf _npos == 8
	
		//Atualiza campo de valores do custo operacional
		_nval := IIf(ZTRB->COMPOR == 'CADASTRO', _aList[_oBrowse:nAt][2],ZTRB->CUSTOO)
		
		If ZTRB->COMPOR == 'CADASTRO'
		
			_aList[_npos][2] :=	(_nprod * _aList[_npos][3] )
				
		Else
		
			_aList[_npos][2] :=	ZTRB->CUSTOO + (_nprod * _aList[_npos][5] )
			_aList[_npos][3] :=	(ZTRB->CUSTOO/_nprod) +  _aList[_npos][5]
			
		EndIf 
			
	EndIf
	
	If _npos != 8 .And. _npos != 11 .And. _npos != 12 .And. _npos != 13
	
		//Atualiza campo de valores do leite e do custo total
		_aList[_npos][2] :=	_nval +  (_aList[_npos][5]  * _nprod) 
	   	_aList[_npos][3] :=	_aList[_npos][2] / _nprod  
		
//		_aList[1][2] :=  ZTRB->CUSTOP +  ( ( _aList[2][5] + _aList[3][5] + _aList[4][5] + _aList[5][5] + _aList[6][5] ) * _nprod )
//		_aList[1][3] :=  (_aList[1][2] / _nprod) 
		_aList[1][2] := _aList[2][2] + _aList[3][2] + _aList[4][2] + _aList[5][2] + _aList[6][2]  //custo produção
		_aList[1][3] := _aList[2][3] + _aList[3][3] + _aList[4][3] + _aList[5][3] + _aList[6][3]  //custo produção unitario
	
	EndIf                                                              
	
	If _npos == 11 .Or. _npos == 12 .Or. _npos == 13
	
		//Atualiza campo de valores do leite e do custo total
		_aList[_npos][2] :=	_nval +  (_aList[_npos][5]  * _nprod) 
	   	_aList[_npos][3] :=	_aList[_npos][2] / _nprod  

	EndIf 
	
	//atualiza campos intermediários para origem de cadastro
	If ZTRB->COMPOR == 'CADASTRO'
	
		_aList[1][2] := _aList[2][2] + _aList[3][2] + _aList[4][2] + _aList[5][2] + _aList[6][2]  //custo produção
		_aList[1][3] := _aList[2][3] + _aList[3][3] + _aList[4][3] + _aList[5][3] + _aList[6][3]  //custo produção unitario
		
	EndIf	
	
	//atualiza campos de custo total
	_aList[15][2]	:= _aList[1][2] + _aList[8][2] + _aList[11][2] + _aList[12][2] + _aList[13][2]
	_aList[15][3]	:= _aList[1][3] + _aList[8][3] + _aList[11][3] + _aList[12][3] + _aList[13][3]

	//Atualiza campos de valor de margem 
	_aList[17][3] :=  _aList[19][3] - _aList[15][3]
	_aList[17][2] :=  _aList[17][3] * _nprod
	_aList[17][4] :=  (_aList[17][2] / ( _aList[19][3] * _nprod )) * 100
	
	//Atualiza campo de faturamento potencial
	_aList[19][2] := _aList[19][3] * _nprod
	
	//Atualiza campos de porcentagem de custos
	_aList[15][4] := 100 - _aList[17][4]
	_aList[1][4] := (_aList[15][4] * _aList[1][2])/_aList[15][2]
	_aList[2][4] := (_aList[15][4] * _aList[2][2])/_aList[15][2]
	_aList[3][4] := (_aList[15][4] * _aList[3][2])/_aList[15][2]
	_aList[4][4] := (_aList[15][4] * _aList[4][2])/_aList[15][2]
	_aList[5][4] := (_aList[15][4] * _aList[5][2])/_aList[15][2]
	_aList[6][4] := (_aList[15][4] * _aList[6][2])/_aList[15][2]
	_aList[8][4] := (_aList[15][4] * _aList[8][2])/_aList[15][2]
	_aList[11][4] := (_aList[15][4] * _aList[11][2])/_aList[15][2]
	_aList[12][4] := (_aList[15][4] * _aList[12][2])/_aList[15][2]
	_aList[13][4] := (_aList[15][4] * _aList[13][2])/_aList[15][2]
	
EndIf


If _aList[_oBrowse:nAt][1] == "Margem"

	If _oBrowse:ncolpos == 4
	
		//Edita campo de % da margem
		_lsai := .T.
		lEditCell(_aList,_oBrowse,"@E 999,999,999.999999",4)
					
		//Atualiza campos de valor de margem 
		_aList[17][3] :=  (_aList[15][3] / _aList[15][4]) * _aList[17][4]
		_aList[17][2] :=  (_aList[15][2] / _aList[15][4]) * _aList[17][4]
		
	ElseIf _oBrowse:ncolpos == 3
	
		//Edita campo de valor da margem
		_lsai := .T.
		
			lEditCell(_aList,_oBrowse,"@E 999,999,999.999999",3)
		//Atualiza campos de valor de margem 
		_aList[17][4] :=  (_aList[17][3] / (_aList[17][3] + _aList[15][3])) * 100 
		_aList[17][2] :=  (_aList[15][2] / _aList[15][4]) * _aList[17][4]
		
	EndIf
	//Atualiza campos de porcentagem de custos
	_aList[15][4] := 100 - _aList[17][4]
	_aList[1][4] := (_aList[15][4] * _aList[1][2])/_aList[15][2]
	_aList[2][4] := (_aList[15][4] * _aList[2][2])/_aList[15][2]
	_aList[3][4] := (_aList[15][4] * _aList[3][2])/_aList[15][2]
	_aList[4][4] := (_aList[15][4] * _aList[4][2])/_aList[15][2]
	_aList[5][4] := (_aList[15][4] * _aList[5][2])/_aList[15][2]
	_aList[6][4] := (_aList[15][4] * _aList[6][2])/_aList[15][2]
	_aList[8][4] := (_aList[15][4] * _aList[8][2])/_aList[15][2]
			
	//Atualiza campos de preco
	_aList[19][3] := _aList[15][3] + _aList[17][3]
	_aList[19][2] := _aList[19][3] * _nprod

ElseIf _aList[_oBrowse:nAt][1] == "Fat Potencial/Preco"
	
	//Edita campo de valor do preco unitario
	lEditCell(_aList,_oBrowse,"@E 999,999,999.999999",3)
	
	//Atualiza campos de valor de margem 
	_aList[17][3] :=  _aList[19][3] - _aList[15][3]
	_aList[17][2] :=  _aList[17][3] * _nprod
	_aList[17][4] :=  (_aList[17][2] / ( _aList[19][3] * _nprod )) * 100
	
	//Atualiza campo de faturamento potencial
	_aList[19][2] := _aList[19][3] * _nprod
	
	//Atualiza campos de porcentagem de custos
	_aList[15][4] := 100 - _aList[17][4]
	_aList[1][4] := (_aList[15][4] * _aList[1][2])/_aList[15][2]
	_aList[2][4] := (_aList[15][4] * _aList[2][2])/_aList[15][2]
	_aList[3][4] := (_aList[15][4] * _aList[3][2])/_aList[15][2]
	_aList[4][4] := (_aList[15][4] * _aList[4][2])/_aList[15][2]
	_aList[5][4] := (_aList[15][4] * _aList[5][2])/_aList[15][2]
	_aList[6][4] := (_aList[15][4] * _aList[6][2])/_aList[15][2]
	_aList[8][4] := (_aList[15][4] * _aList[8][2])/_aList[15][2]
	
EndIf

If ZTRB->COMPOR == 'CADASTRO' //ATUALIZA MARGEM REALIZADA SE É PREÇO POR CADASTRO
	_aList[17][4] :=  ((_aList[19][2] - _aList[15][2]) / _aList[19][2]) * 100
EndIf
	
_oBrowse:DrawSelect()
_oBrowse:gotop()
_oBrowse:GoPosition(_npos)

Return

/*
===============================================================================================================================
Programa----------: CEST002R
Autor-------------: Josue Danich Prestes
Data da Criacao---: 12/01/2016
Descrição---------: Tela de atualização de  dados atuais de custo
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function CEST002R()

Local _oDlg2 		:= nil
Local _acomps		:= {}
Local _np			:= 0
Local _ocomps		:= nil
Local _ccomps		:= ""

//Carrega competências disponíveis
DBSelectArea("ZTRB")
ZTRB->( DBGoTop() )

//Adiciona opção de origem do cadastro de produtos
aAdd(_acomps, "CADASTRO PROD.")
aAdd(_acomps, "LIMPA ATUAL")

While .not. ZTRB->( Eof() )

	_np := aScan(_acomps, AllTrim(ZTRB->MESANO) )
	
	If _np == 0 .And. AllTrim(ZTRB->MESANO) != "ATUAL"
	
		aAdd(_acomps, AllTrim(ZTRB->MESANO))
		
	EndIf
	
	ZTRB->( DBSkip() )
	
EndDo

nLinha:=10
_nCol:=15

DEFINE MSDIALOG _oDlg2 TITLE ("Refaz Dados Atuais") From 0,0 To 185, 300 OF oMainWnd PIXEL
                                                                       
@ nLinha,_nCol Say OemToAnsi("Escolha a competência de origem:")
nLinha+=12

_ocomps := TComboBox():New(nLinha,_nCol,{|u|If(PCount()>0,_ccomps:=u,_ccomps)}, _acomps,100,20,_oDlg2,,,,,,.T.,,,,,,,,,'') //40
//aAdd( _aButtons, {"Gera dados", {|| Processa({|| CEST002G(_odlg2,_acomps[_ocomps:nAt]),_oDlg2:End()},"Gera dados","Aguarde a geração de dados...")}, "Gerando dados...", "Gera Dados" , {|| .T.}} )     	
nLinha+=38

@ nLinha,_nCol    Button "Refaz dados" SIZE 41,15 ACTION ( Processa( {|| CEST002G(_odlg2,_acomps[_ocomps:nAt])},,"Aguarde a geração de dados...") , _oDlg2:End()) Pixel 
@ nLinha,_nCol+57 Button "Cancela"     SIZE 41,15 ACTION ( _oDlg2:End() ) Pixel 

ACTIVATE MSDIALOG _oDlg2 //ON INIT EnchoiceBar(_oDlg2,{||_oDlg2:End()},{||_oDlg2:End()},,_abuttons,,,,,,.F.) CENTERED

Return

/*
===============================================================================================================================
Programa----------: CEST002G
Autor-------------: Josue Danich Prestes
Data da Criacao---: 12/01/2016
Descrição---------: Refaz dados atuais de custo
Parametros--------: _odlg2 - objeto da tela de diálogo
					  _ccomp - competência de origem
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CEST002G(_odlg2,_ccomp)

Local _nret 		:= 0
Local _nfatura 	:= 0
Local _nqtdpro 	:= 0
Local _nqtdfat 	:= 0
Local _nPrcmin 	:= 0
Local _nPrcmax 	:= 0
Local _cQuery 	:= ""
Local _ddtini		:= ddatabase
Local _ddtfim		:= ddatabase

ProcRegua( 0 )
   
_ddtfim := SToD(StrZero(year(_ddtini),4) + StrZero(month(_ddtini),2)+"01") - 1

If month(_ddtini) == 01
	_ddtini:= SToD(StrZero(year(_ddtini)-1,4) + "1201")	
Else
	_ddtini := SToD(StrZero(year(_ddtini),4) + StrZero(month(_ddtini)-1,2)+"01")
EndIf

//apaga registros se existirem após avisar
DBSelectArea("ZE1")
ZE1->( dbSetFilter( { || AllTrim(ZE1->ZE1_COMP) == 'ATUAL' .And. ZE1->ZE1_FILIAL = xFilial("ZE1") },;
			 "AllTrim(ZE1->ZE1_COMP) == 'ATUAL' .And. ZE1->ZE1_FILIAL = xFilial('ZE1')") )
ZE1->( DBGoTop() )

If .not. ZE1->( Eof() )

	_nret := MessageBox("Existem registros de análise atual, serão apagados, continua?","Alerta!", 49)
	
	If _nret == 2
		Return
	EndIf
	
EndIf

ProcRegua( ZTRB->( Lastrec())*2 )

While .not. ZE1->( Eof() ) 

    IncProc()
	RecLock("ZE1",.F.)
	ZE1->( Dbdelete() )
	ZE1->(MSUnLock()) 
	
	ZE1->( DBSkip() )
	
EndDo

ZE1->( Dbclearfilter() )    

DBSelectArea("ZTRB")
ZTRB->( dbSetFilter( { || AllTrim(ZTRB->MESANO) = 'ATUAL' }, "AllTrim(ZTRB->MESANO) = 'ATUAL'" ) )
ZTRB->( DBGoTop() )

While .not. ZTRB->( Eof() ) 
   IncProc()
	ZTRB->( Dbdelete() )
	ZTRB->( DBSkip() )
EndDo

ZTRB->( Dbclearfilter() )

_oBrw:Refresh()
//Se For só para limpar o atual já sai da rotina
If _ccomp == "LIMPA ATUAL"
	MessageBox("Registros da competência atual deletados com sucesso","Processo Concluido", 64)
	Return
EndIf

If _ccomp != "CADASTRO PROD."
	//cria novos registros para análise de preço atual
	DBSelectArea("ZTRB")
	ZTRB->( dbSetFilter( { || AllTrim(ZTRB->MESANO) = AllTrim(_ccomp) }, "AllTrim(ZTRB->MESANO) = '" + AllTrim(_ccomp) + "'" ) )
	count to nTot
	ZTRB->( DBGoTop() )

    ProcRegua( nTot )

	While .not. ZTRB->( Eof() )

       IncProc()
		RecLock("ZE1",.T.)    
		
		ZE1->ZE1_FILIAL 	:= xFilial("ZE1")
		ZE1->ZE1_PRODUT 	:= ZTRB->PRODUTO
		ZE1->ZE1_CUSTOP		:= ZTRB->CUSTOP
		ZE1->ZE1_FATURA		:= ZTRB->FATURA
		ZE1->ZE1_QTDFAT		:= ZTRB->QTDFAT
		ZE1->ZE1_QTDPRO		:= ZTRB->QTDPRO
		ZE1->ZE1_CUSTOO		:= ZTRB->CUSTOO
		ZE1->ZE1_COMP			:= 'ATUAL'
		ZE1->ZE1_CUSTOE		:= ZTRB->CUSTOE
		ZE1->ZE1_CUSTOF		:= ZTRB->CUSTOF
		ZE1->ZE1_CUSTOI		:= ZTRB->CUSTOI
		ZE1->ZE1_CUSTOU		:= ZTRB->CUSTOU
		ZE1->ZE1_CUSTOL		:= ZTRB->CUSTOL
		ZE1->ZE1_COMPOR		:= ZTRB->MESANO
		ZE1->ZE1_GRUPO		:= ZTRB->GRUPO
		ZE1->ZE1_MARGEM		:= (ZTRB->FATURA/ZTRB->QTDFAT)-((ZTRB->CUSTOO+ZTRB->CUSTOP)/ZTRB->QTDPRO)
		
		ZE1->(MSUnLock())       
		ZTRB->( DBSkip() )
	EndDo

	ZTRB->( Dbclearfilter() )

ElseIf _ccomp == "CADASTRO PROD."

	DBSelectArea("SB1")
	SB1->( dbSetFilter( { || AllTrim(B1_TIPO) = "PA" .And. AllTrim(B1_MSBLQL) != "1" .And. Posicione("SBZ",1,SB1->B1_FILIAL+SB1->B1_COD,"BZ_I_OBSOL") != "S" },;
				 'AllTrim(B1_TIPO) = "PA" .And. AllTrim(B1_MSBLQL) != "1" .And. Posicione("SBZ",1,SB1->B1_FILIAL+SB1->B1_COD,"BZ_I_OBSOL") != "S"' ) )
	count to nTot
	SB1->( DBGoTop() )

    ProcRegua( nTot )

	While .not. SB1->( Eof() )
	   IncProc()
		//procura preço mínimo, preço máximo, total de faturamento e quantidade faturada
		_cQuery	:= " SELECT " 
	
		_cQuery  	+= " D2_COD, " 
		_cQuery  	+= " Round(MAX( ( D2_VALBRUT - ( D2_I_FRET + D2_VALICM + D2_VALIMP5 + D2_VALIMP6 + D2_VALIPI ) ) / D2_QUANT ),2) AS PRCMAX, "
		_cQuery  	+= " Round(MIN( ( D2_VALBRUT - ( D2_I_FRET + D2_VALICM + D2_VALIMP5 + D2_VALIMP6 + D2_VALIPI ) ) / D2_QUANT ),2) AS PRCMIN, "
	 	_cQuery  	+= " SUM( D2_QUANT ) AS QTDE, "
	 	_cQuery  	+= " SUM( D2_VALBRUT - ( D2_I_FRET + D2_VALICM + D2_VALIMP5 + D2_VALIMP6 + D2_VALIPI ) ) AS FATUR "
		_cQuery  	+= " FROM " + RetSqlName("SD2") + " SD2 JOIN  " + RetSqlName("SF4") + " SF4 ON  SF4.F4_FILIAL = SD2.D2_FILIAL AND SF4.F4_CODIGO = SD2.D2_TES"
		_cQuery  	+= " WHERE SD2.D2_FILIAL = '" + xFilial("SD2") + "'"
		_cQuery   	+= " AND SD2.D2_EMISSAO >= '" + DToS(_ddtini) + "' AND D2_EMISSAO <= '" + DToS(_ddtfim) + "' "
		_cQuery   	+= " AND SD2.D2_QUANT > 0 "
		_cQuery  	+= " AND SD2.D2_COD = '" + AllTrim(SB1->B1_COD)	 +  "' "
		_cQuery  	+= " AND SF4.D_E_L_E_T_ = ' ' "
		_cQuery  	+= " AND SF4.F4_FILIAL = '" + xFilial("SF4") + "' "
		_cQuery 	+= " AND SF4.F4_DUPLIC = 'S'	"
		_cQuery 	+= " AND SF4.F4_ESTOQUE= 'S'	"
		_cQuery 	+= " GROUP BY D2_COD "
		_cQuery := ChangeQuery(_cQuery)

		MPSysOpenQuery(_cQuery,"SD2T")
 	
		If !SD2T->( Eof() )
			_nPrcmin := SD2T->PRCMIN
			_nPrcmax := SD2T->PRCMAX
			_nfatura := SD2T->FATUR
			_nqtdfat := SD2T->QTDE
		Else
			_nfatura := 0
			_nqtdfat := 0
			_nPrcmin := 0
			_nPrcmax := 0
		EndIf
		
		//procura total produzido
		_cQuery	:= " SELECT " 
		_cQuery  	+= " SUM( D3_QUANT ) AS QTDE "
		_cQuery  	+= " FROM " + RetSqlName("SD3") + " SD3"
		_cQuery  	+= " WHERE SD3.D3_FILIAL = '" + xFilial("SD3") + "'"
		_cQuery   	+= " AND SD3.D3_EMISSAO >= '" + DToS(_ddtini) + "' AND SD3.D3_EMISSAO <= '" + DToS(_ddtfim) + "' "
		_cQuery   	+= " AND SD3.D3_CF = 'PR0' "
		_cQuery  	+= " AND SD3.D3_COD = '" + AllTrim(SB1->B1_COD)	 +  "' "
		_cQuery  	+= " AND SD3.D3_ESTORNO <> 'S' "
		_cQuery  	+= " AND SD3.D_E_L_E_T_ = ' '"
		_cQuery := ChangeQuery(_cQuery)

		MPSysOpenQuery(_cQuery,"SD3T")			
		
		If !SD3T->( Eof() )
			_nqtdpro := SD3T->QTDE
		Else
			_nqtdpro := 0
		EndIf

		RecLock("ZE1",.T.)    
		
		ZE1->ZE1_FILIAL 	:= xFilial("ZE1")
		ZE1->ZE1_PRODUT 	:= SB1->B1_COD
		ZE1->ZE1_CUSTOP		:= 0
		ZE1->ZE1_FATURA		:= _nfatura
		ZE1->ZE1_QTDFAT		:= _nqtdfat
		ZE1->ZE1_QTDPRO		:= _nqtdpro
		ZE1->ZE1_COMP			:= 'ATUAL'
		ZE1->ZE1_COMPOR		:= 'CADASTRO'   
		ZE1->ZE1_GRUPO		:= Posicione("SBM",1,xFilial("SBM")+SB1->B1_GRUPO,"BM_DESC")
		ZE1->ZE1_PRCMIN		:= _nPrcmin
		ZE1->ZE1_PRCMAX		:= _nPrcmax
				
		ZE1->(MSUnLock()) 
		      
		SD2T->( DBCloseArea() )
		SD3T->( DBCloseArea() )
		SB1->( DBSkip() )
	EndDo

	SB1->( Dbclearfilter() )
EndIf

//======================================================================
//Atualiza browse a partir das alterações na ZE1
//======================================================================

DBSelectArea("ZE1")
ZE1->( dbSetFilter( { || AllTrim(ZE1->ZE1_COMP) = 'ATUAL' .And. ZE1->ZE1_FILIAL = xFilial('ZE1') },;
					 "AllTrim(ZE1->ZE1_COMP) = 'ATUAL' .And. ZE1->ZE1_FILIAL = xFilial('ZE1')" ) )
count to nTot
ZE1->( DBGoTop() )

ProcRegua( nTot )

While !ZE1->( Eof() )

   IncProc("Atualizando Prod.: "+ZE1->ZE1_PRODUT)
	ZTRB->(DBAPPEND())    
	
	ZTRB->MESANO	:= 'ATUAL'	
	ZTRB->PRODUTO   := AllTrim(ZE1->ZE1_PRODUT)
	ZTRB->DESCR      := AllTrim(Posicione("SB1",1,xFilial("SB1")+ZE1->ZE1_PRODUT,"B1_DESC"))
	ZTRB->CUSTO	    := Round(((ZE1->ZE1_CUSTOP + ZE1->ZE1_CUSTOO+ ZE1->ZE1_REJCC + ZE1->ZE1_REJIMP + ZE1->ZE1_REJVBA ) / IIf(ZE1->ZE1_QTDPRO > 0, ZE1->ZE1_QTDPRO,1)),2)
	ZTRB->PRCMED	:= Round((ZE1->ZE1_FATURA / ZE1->ZE1_QTDFAT),2)
	ZTRB->QTDPRO	:= ZE1->ZE1_QTDPRO
	ZTRB->QTDFAT	:= ZE1->ZE1_QTDFAT
	ZTRB->CUSTOO	:= ZE1->ZE1_CUSTOO
	ZTRB->CUSTOP	:= ZE1->ZE1_CUSTOP
	ZTRB->FATURA	:= ZE1->ZE1_FATURA
	ZTRB->CUSTOE	:= ZE1->ZE1_CUSTOE
	ZTRB->CUSTOF	:= ZE1->ZE1_CUSTOF
	ZTRB->CUSTOI	:= ZE1->ZE1_CUSTOI
	ZTRB->CUSTOU	:= ZE1->ZE1_CUSTOU
	ZTRB->CUSTOL	:= ZE1->ZE1_CUSTOL
	ZTRB->COMPOR	:= ZE1->ZE1_COMPOR
	ZTRB->GRUPO	    := ZE1->ZE1_GRUPO
	ZTRB->MRGP		:= Round(((((IIf(ZE1->ZE1_QTDPRO > 0,ZE1->ZE1_QTDPRO,1) * ZTRB->PRCMED) - (ZE1->ZE1_CUSTOP + ZE1->ZE1_CUSTOO)))/(IIf(ZE1->ZE1_QTDPRO>0,ZE1->ZE1_QTDPRO,1) * ZTRB->PRCMED))*100 ,2)
	ZTRB->MARGEM	:= ZE1->ZE1_MARGEM
		
	ZE1->( DBSkip() )
	
EndDo

ZE1->( Dbclearfilter() )

_oBrw:Refresh()

MessageBox("Registros da competência atual criados com sucesso","Processo Concluido", 64)

Return

/*
===============================================================================================================================
Programa----------: CEST002N
Autor-------------: Josue Danich Prestes
Data da Criacao---: 12/01/2016
Descrição---------: Grava valores de reajuste da tela de análise de preços
Parametros--------: _alist - dados do browse
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CEST002N(_aList)

DBSelectArea("ZE1")
ZE1->( dbSetFilter( { || AllTrim(ZE1_COMP) = 'ATUAL' .And. AllTrim(ZE1_PRODUT) == AllTrim(ZTRB->PRODUTO) .And. ZE1_FILIAL = xFilial('ZE1') },;
			 "AllTrim(ZE1->ZE1_COMP) = 'ATUAL' .And. AllTrim(ZE1_PRODUT) == AllTrim(ZTRB->PRODUTO) .And. ZE1_FILIAL = xFilial('ZE1')" ) )
count to nTot
ZE1->( DBGoTop() )

ProcRegua( nTot )
If !ZE1->( Eof() )

	//Atualiza valores de reajuste na tela
	//RecLock("ZTRB",.F.) 
	IncProc()
	ZTRB->REAJL	:=  _aList[2][5]
	ZTRB->REAJE	:=  _aList[3][5]	
	ZTRB->REAJI	:=  _aList[4][5]
	ZTRB->REAJF	:=  _aList[5][5]
	ZTRB->REAJU	:=  _aList[6][5]
	ZTRB->REAJO	:=  _aList[8][5]
	ZTRB->REJCC	:=  _aList[13][5]
	ZTRB->REJIMP:=  _aList[12][5]
	ZTRB->REJVBA:=  _aList[11][5]
	ZTRB->PRECOR:=  _aList[19][3]
	ZTRB->PRCMED:=	_aList[19][3]
	
	If ZTRB->COMPOR == 'CADASTRO'
		ZTRB->CUSTOO 	:= _aList[8][2]
		ZTRB->CUSTOL 	:= _aList[2][2]
		ZTRB->CUSTOE 	:= _aList[3][2]
		ZTRB->CUSTOF 	:= _aList[5][2]
		ZTRB->CUSTOI 	:= _aList[4][2]
		ZTRB->CUSTOU 	:= _aList[6][2]
		ZTRB->CUSTOP 	:= _aList[1][2]
		ZTRB->CUSTO  	:= _aList[15][3] 
		ZTRB->MRGP	   	:= _aList[17][4]
		ZTRB->MARGEM 	:= _aList[17][3]
	Else
		ZTRB->CUSTO	    := _aList[15][3]//Round(((_ncustopr + _ncustoop) / IIf(ZE1->ZE1_QTDPRO>0,ZE1->ZE1_QTDPRO,1)),2)
		ZTRB->CUSTOP	:= _aList[01][2]//Round((_ncustopr),2)
		ZTRB->CUSTOO	:= _aList[08][2]//Round((_ncustoop),2)
		ZTRB->MRGP		:= _aList[17][4]	
		ZTRB->MARGEM 	:= _aList[17][3]
	EndIf
		
	//Atualiza valores de reajuste na base de dados
	RecLock("ZE1",.F.) 
	
	ZE1->ZE1_REAJL		:= ZTRB->REAJL
	ZE1->ZE1_REAJE		:= ZTRB->REAJE
	ZE1->ZE1_REAJI		:= ZTRB->REAJI
	ZE1->ZE1_REAJF		:= ZTRB->REAJF
	ZE1->ZE1_REAJU		:= ZTRB->REAJU
	ZE1->ZE1_REAJO		:= ZTRB->REAJO
	ZE1->ZE1_REJCC		:= ZTRB->REJCC
	ZE1->ZE1_REJIMP		:= ZTRB->REJIMP
	ZE1->ZE1_REJVBA		:= ZTRB->REJVBA
	ZE1->ZE1_PRECOR		:= ZTRB->PRECOR
	ZE1->ZE1_REJCC		:= ZTRB->REJCC
	ZE1->ZE1_REJIMP		:= ZTRB->REJIMP
	ZE1->ZE1_REJVBA		:= ZTRB->REJVBA
	ZE1->ZE1_MARGEM		:= ZTRB->MARGEM
	ZE1->ZE1_CUSTOP		:= ZTRB->CUSTOP
		
	If ZTRB->COMPOR == 'CADASTRO'
		ZE1->ZE1_CUSTOO := _aList[8][2]
		ZE1->ZE1_CUSTOL := _aList[2][2]
		ZE1->ZE1_CUSTOE := _aList[3][2]
		ZE1->ZE1_CUSTOF := _aList[5][2]
		ZE1->ZE1_CUSTOI := _aList[4][2]
		ZE1->ZE1_CUSTOU := _aList[6][2]
		ZE1->ZE1_CUSTOP := _aList[1][2]
	EndIf
	
	ZE1->(MSUnLock())
EndIf

ZE1->( DbClearFilter() )
_oBrw:Refresh()

Return

/*
===============================================================================================================================
Programa----------: CEST002V
Autor-------------: Josue Danich Prestes
Data da Criacao---: 12/01/2016
Descrição---------: Tela de Reajuste valores para todas as linhas da competência ATUAL
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function CEST002V()

Local _oDlg2 		:= nil
Local _acomps		:= {}
Local _nval		:= 0
Local _npval		:= 0
Local _ocomps		:= nil
Local _ccomps		:= ""
Local _ogrup		:= nil
Local _cgrup		:= ""
Local _agrup		:= {}
Local _nvval		:= 0
	
aAdd(_acomps, "Leite - MP")
aAdd(_acomps, "Embalagens")
aAdd(_acomps, "Insumos")
aAdd(_acomps, "Frete")
aAdd(_acomps, "Outros")
aAdd(_acomps, "Custo Operacional")
aAdd(_acomps, "Preco")
aAdd(_acomps, "Margem")
aAdd(_acomps, "Custo Corporativo")
aAdd(_acomps, "Imposto")
aAdd(_acomps, "Verba")

//monta array de grupos de produtos
ZTRB->( DBGoTop() )

aAdd(_agrup,"  TODOS")
_ccomps := "  TODOS"

While !ZTRB->( Eof() )
	If aScan(_agrup, AllTrim( ZTRB->GRUPO ) ) == 0 .And. AllTrim(ZTRB->MESANO) == "ATUAL" 
		aAdd(_agrup, AllTrim( ZTRB->GRUPO ))
	EndIf
	
	ZTRB->( DBSkip() )
EndDo		

_agrup := aSort(_agrup)
		
DEFINE MSDIALOG _oDlg2 TITLE OemToAnsi("Reajusta Dados Atuais") From 0,0 To 350, 280 OF oMainWnd PIXEL

@ 10 ,10.8 Say OemToAnsi("Escolha o tipo de custo:")

_ocomps := TComboBox():New(20,10.8,{|u|If(PCount()>0,_ccomps:=u,_ccomps)}, _acomps,100,20,_oDlg2,,,,,,.T.,,,,,,,,,'')

@ 40 ,10.8 Say OemToAnsi("Escolha o grupo:")

_ogrup := TComboBox():New(50,10.8,{|u|If(PCount()>0,_cgrup:=u,_cgrup)}, _agrup,100,20,_oDlg2,,,,,,.T.,,,,,,,,,'')

nLinha:=70
_nCol :=10
_nCol2:=_nCol+67

@ nLinha,_nCol  Say OemToAnsi("% Aumento / Margem:")
@ nLinha,_nCol2 Get _npval picture "@E 999.99" 
nLinha+=17

@ nLinha,_nCol  Say OemToAnsi("Valor Aumento:")
@ nLinha,_nCol2 Get _nvval picture "@E 999.99"
nLinha+=17

@ nLinha,_nCol  Say OemToAnsi("Novo Valor:")
@ nLinha,_nCol2 Get _nval picture "@E 999.99"
nLinha+=45

@ nLinha,_nCol  Button "Reajusta dados" SIZE 50,15 ACTION ( Processa( {|| CEST002Y(_odlg2,_acomps[_ocomps:nAt],_nval,_npval,_agrup[_ogrup:nAt], _nvval ) },, "Reajusta Dados..." ) , _oDlg2:End()) Pixel 
@ nLinha,_nCol2 Button "Cancela"        SIZE 40,15 ACTION ( _oDlg2:End() ) Pixel 

ACTIVATE MSDIALOG _oDlg2 //ON INIT EnchoiceBar(_oDlg2,{||_oDlg2:End()},{||_oDlg2:End()},,_abuttons,,,,,,.F.) CENTERED

Return

/*
===============================================================================================================================
Programa----------: CEST002P
Autor-------------: Alex Walaluer
Data da Criacao---: 06/06/2016
Descrição---------: Tela de Geracao de tabelas de precos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function CEST002P()

Local _bOK  :={|| NaoVazio(_nMaximo) .And. Positivo(_nMaximo) .And. NaoVazio(_nMinimo) .And. Positivo(_nMinimo)} 
Local _oDlg2:= nil
Local nLinha:=10
Local _nCol :=10
Local _nCol2:=_nCol+85
Private _dData  :=(dDataBase+30)
Private _nMaximo:=0
Private _nMinimo:=0
		
DEFINE MSDIALOG _oDlg2 TITLE OemToAnsi("Gera Tabela de Preços") From 0,0 To 200, 310 OF oMainWnd PIXEL

@ nLinha,_nCol  Say OemToAnsi("Data de Vigência")
@ nLinha,_nCol2 Get _dData   picture "@D"       SIZE 42,10 VALID NaoVazio(_dData)
nLinha+=15

@ nLinha,_nCol  Say OemToAnsi("Multiplicador de Preço Máximo:")
@ nLinha,_nCol2 Get _nMaximo picture "@E 99.99" SIZE 42,10 VALID NaoVazio(_nMaximo) .And. Positivo(_nMaximo)
nLinha+=15

@ nLinha,_nCol  Say OemToAnsi("Multiplicador de Preço Mínimo:")
@ nLinha,_nCol2 Get _nMinimo picture "@E 99.99" SIZE 42,10 VALID NaoVazio(_nMinimo) .And. Positivo(_nMinimo)
nLinha+=20

@ nLinha,_nCol  Button "Gera tabela de preços"  SIZE 65,15 ACTION ( If(EVAL(_bOK),(Processa( {|| U_CEST002D() },, "Gera Tabela de Preços..." ) , _oDlg2:End()) ,)) Pixel 
@ nLinha,_nCol2 Button "Cancela"                SIZE 42,15 ACTION ( _oDlg2:End() ) Pixel 

ACTIVATE MSDIALOG _oDlg2 

Return

/*
===============================================================================================================================
Programa----------: CEST002Y
Autor-------------: Josue Danich Prestes
Data da Criacao---: 12/01/2016
Descrição---------: Reajusta valores para todas as linhas da competência ATUAL
Parametros--------: _odlg2 - objeto da tela de reajuste
					  _ctipo - tipo de reajuste
					  _nval - valor do item
					  _npval - porcentagem do reajuste
					  _cgrupo - grupo para filtrar o reajuste
					  _nvval - valor do reajuste
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CEST002Y(_odlg2,_ctipo,_nval,_npval,_cgrupo,_nvval)

Local _ncustoop 	:= 0
Local _ncustopr 	:= 0
Local _nprod		:= 0
Local _lzera		:= .F.

//Verifica se apenas um dos valores foi preenchido
If (_nval != 0 .And. _npval != 0) .Or. (_nval != 0 .And. _nvval != 0) .Or. (_npval != 0 .And. _nvval != 0)
	MessageBox("Preencha apenas uma das opções.","Alerta", 16)
	Return
EndIf

//Verifica se nenhum dos valores foi preenchido
If _nval == 0 .And. _npval == 0 .And. _nvval == 0
	If MessageBox("Zera valores?","Atenção", 4) == 6
		_lzera := .T.
	EndIf
EndIf

//Atualiza reajuste escolhido para todos os itens da tela
DBSelectArea("ZTRB")

If _cgrupo == "  TODOS"
	ZTRB->( dbSetFilter( { || AllTrim(ZTRB->MESANO) = "ATUAL" }, "AllTrim(ZTRB->MESANO) = 'ATUAL'" ) )
Else
	ZTRB->( dbSetFilter( { || AllTrim(ZTRB->MESANO) = "ATUAL" .And. AllTrim(ZTRB->GRUPO) == AllTrim(_cgrupo)},;
						 "AllTrim(ZTRB->MESANO) = 'ATUAL' .And. AllTrim(ZTRB->GRUPO) == AllTrim(_cgrupo)" ) )
EndIf

count to nTot
ZTRB->( DBGoTop() )

ProcRegua( nTot )
ZE1->(DBSetOrder(1))

While !ZTRB->( Eof() )
   IncProc()
	If !ZE1->(DBSeek(xFilial("ZE1") + 'ATUAL     ' + ZTRB->PRODUTO))
	   ZTRB->( DBSkip() )
	   Loop
	EndIf
	
	//=========================================================================
	//Se For preco de origem do cadastro grava reajuste direto em custos
	//se For de origem de uma competencia grava % de reajuste
	//==========================================================================
	
	If ZTRB->COMPOR == 'CADASTRO'
		If ZE1->ZE1_QTDPRO == 0
			_nprod := 1
		Else
			_nprod := ZE1->ZE1_QTDPRO
		EndIf
	
		If _ctipo ==  "Leite - MP"
			If _npval != 0 
				ZTRB->CUSTOL += ((_npval * ZTRB->CUSTOL) / 100) * _nprod
			ElseIf _nval != 0
				ZTRB->CUSTOL := _nval * _nprod 
			Else
				ZTRB->CUSTOL :=  ( _nvval * _nprod) + ZTRB->CUSTOL
			EndIf
			
			If _lzera 
				ZTRB->CUSTOL := 0
			EndIf
		EndIf 
	
		If _ctipo ==  "Insumos"
			If _npval != 0
				ZTRB->CUSTOI += (_npval * ZTRB->CUSTOI) / 100
			ElseIf _nval != 0
				ZTRB->CUSTOI := _nval * _nprod
			Else
				ZTRB->CUSTOI :=  ( _nvval * _nprod) + ZTRB->CUSTOI
			EndIf
			
			If _lzera 
				ZTRB->CUSTOI := 0
			EndIf
		EndIf 
	
		If _ctipo ==  "Frete"
			If _npval != 0
				ZTRB->CUSTOF += (_npval * ZTRB->CUSTOF) / 100
			ElseIf _nval != 0
				ZTRB->CUSTOF := _nval * _nprod
			Else
				ZTRB->CUSTOF :=  ( _nvval * _nprod) + ZTRB->CUSTOF
			EndIf
			
			If _lzera 
				ZTRB->CUSTOF := 0
			EndIf
		EndIf 
	
		If _ctipo ==  "Custo Operacional"
			If _npval != 0
				ZTRB->CUSTOO += (_npval * ZTRB->CUSTOO) / 100
			ElseIf _nval != 0
				ZTRB->CUSTOO := _nval * _nprod
			Else
				ZTRB->CUSTOO :=  ( _nvval * _nprod) + ZTRB->CUSTOO
			EndIf
			
			If _lzera 
				ZTRB->CUSTOO := 0
			EndIf
		EndIf 
	
		If _ctipo ==  "Preco"
			If _npval != 0
				ZTRB->PRECOR := ZTRB->PRCMED + ((ZTRB->PRCMED * _npval) / 100 )
				ZTRB->PRCMED := ZTRB->PRCMED + ((ZTRB->PRCMED * _npval) / 100 )
			ElseIf _nval != 0
				ZTRB->PRECOR := _nval 
				ZTRB->PRCMED := _nval 
			Else
				ZTRB->PRECOR := _nvval + ZE1->ZE1_PRCMED 
				ZTRB->PRCMED := _nvval + ZE1->ZE1_PRCMED
			EndIf
			
			If _lzera 
				ZTRB->PRECOR := 0 
				ZTRB->PRCMED := 0
			EndIf
		EndIf 
	
		If _ctipo ==  "Margem"
			If _npval != 0
				ZTRB->MARGEM := (ZTRB->CUSTO * (_npval/100)) / ( 1 - (_npval/100))
				//Se arredondamento joga margem para baixo vai aumentando para garantir o percentual minimo
				While (ZTRB->MARGEM / ZTRB->PRCMED * 100) < _npval
					ZTRB->MARGEM := ZTRB->MARGEM + 0.01
				EndDo
			ElseIf _nval != 0
				ZTRB->MARGEM :=  _nval
			Else
				ZTRB->MARGEM :=  ZTRB->MARGEM + _nvval
			EndIf
			
			If _lzera 
				ZTRB->MARGEM :=  0
			EndIf
		EndIf 
	
		If _ctipo ==  "Embalagens"
			If _npval != 0
				ZTRB->CUSTOE += (_npval * ZTRB->CUSTOE) / 100
			ElseIf _nval != 0
				ZTRB->CUSTOE := _nval * _nprod
			Else
				ZTRB->CUSTOE :=  ( _nvval * _nprod) + ZTRB->CUSTOE				
			EndIf
			
			If _lzera 
				ZTRB->CUSTOE := 0
			EndIf
		EndIf 
	
		If _ctipo ==  "Outros"
			If _npval != 0
				ZTRB->CUSTOU += (_npval * ZTRB->CUSTOU) / 100
			ElseIf _nval != 0
				ZTRB->CUSTOU := _nval * _nprod
			Else
				ZTRB->CUSTOU :=  ( _nvval * _nprod) + ZTRB->CUSTOU
			EndIf
			
			If _lzera 
				ZTRB->CUSTOU := 0
			EndIf
		EndIf 
		
		If _ctipo ==  "Custo Corporativo"
			If _npval > 0
				ZTRB->REJCC := ( _npval * ( ZTRB->REJCC ) ) /100 
			ElseIf _nval != 0
				ZTRB->REJCC := _nval 
			Else
				ZTRB->REJCC :=  ( _nvval) + ZTRB->REJCC
			EndIf
			
			If _lzera 
				ZTRB->REJCC := 0
			EndIf
		EndIf
		
		If _ctipo ==  "Imposto"
			If _npval > 0
				ZTRB->REJIMP := ( _npval * ( ZTRB->REJIMP ) ) /100 
			ElseIf _nval != 0
				ZTRB->REJIMP := _nval 
			Else
				ZTRB->REJIMP :=  ( _nvval ) + ZTRB->REJIMP
			EndIf
			
			If _lzera 
				ZTRB->REJIMP := 0
			EndIf
		EndIf
		
		If _ctipo ==  "Verba"
			If _npval > 0
				ZTRB->REJVBA := ( _npval * ( ZTRB->REJVBA ) ) /100 
			ElseIf _nval != 0
				ZTRB->REJVBA := _nval 
			Else
				ZTRB->REJVBA :=  ( _nvval ) + ZTRB->REJVBA
			EndIf
	
			If _lzera 
				ZTRB->REJVBA := 0
			EndIf
		EndIf
		
		ZTRB->CUSTOP:= ZTRB->CUSTOL + ZTRB->CUSTOE + ZTRB->CUSTOI + ZTRB->CUSTOF + ZTRB->CUSTOU
		ZTRB->CUSTO	:= (ZTRB->CUSTOP + ZTRB->CUSTOO +ZTRB->REJCC + ZTRB->REJIMP + ZTRB->REJVBA) / _nprod
		
		If _ctipo ==  "Preco"
			ZTRB->MARGEM := ZTRB->PRECOR - ZTRB->CUSTO
			ZTRB->MRGP		:= ZTRB->MARGEM / ZTRB->PRCMED * 100
		Else
			ZTRB->PRECOR := ZTRB->CUSTO + ZTRB->MARGEM
			ZTRB->PRCMED := ZTRB->CUSTO + ZTRB->MARGEM 
			ZTRB->MRGP		:= ZTRB->MARGEM / ZTRB->PRCMED * 100 
		EndIf
	Else
		If _ctipo ==  "Leite - MP"
			If _npval > 0
				ZTRB->REAJL := ( _npval * ( ZE1->ZE1_CUSTOL / ZE1->ZE1_QTDPRO ) ) /100 
			ElseIf _nval != 0
				ZTRB->REAJL := _nval - (ZE1->ZE1_CUSTOL / ZE1->ZE1_QTDPRO )
			Else
				ZTRB->REAJL :=  ( _nvval ) + ZTRB->REAJL
			EndIf
			
			If _lzera 
				ZTRB->REAJL := - (ZTRB->CUSTOL / ZTRB->QTDPRO )
			EndIf
		EndIf 
	
		If _ctipo ==  "Insumos"
		   	If _npval > 0
				ZTRB->REAJI := ( _npval * ( ZE1->ZE1_CUSTOI / ZE1->ZE1_QTDPRO ) ) /100 
			ElseIf _nval != 0
				ZTRB->REAJI := _nval - (ZE1->ZE1_CUSTOI / ZE1->ZE1_QTDPRO )
			Else
				ZTRB->REAJI :=  ( _nvval ) + ZTRB->REAJI
			EndIf
			
			If _lzera 
				ZTRB->REAJI := - (ZTRB->CUSTOI / ZTRB->QTDPRO )
			EndIf
		EndIf 
	
		If _ctipo ==  "Frete"
	       If _npval > 0
				ZTRB->REAJF := ( _npval * ( ZE1->ZE1_CUSTOF / ZE1->ZE1_QTDPRO ) ) /100 
			ElseIf _nval != 0
				ZTRB->REAJF := _nval - (ZE1->ZE1_CUSTOF / ZE1->ZE1_QTDPRO )
			Else
				ZTRB->REAJF :=  ( _nvval ) + ZTRB->REAJF
			EndIf
			
			If _lzera 
				ZTRB->REAJF := - (ZTRB->CUSTOF / ZTRB->QTDPRO )
			EndIf
		EndIf 
	
		If _ctipo ==  "Custo Operacional"
		   If _npval > 0
				ZTRB->REAJO := ( _npval * ( ZE1->ZE1_CUSTOO / ZE1->ZE1_QTDPRO ) ) /100 
			ElseIf _nval != 0
				ZTRB->REAJO := _nval - (ZE1->ZE1_CUSTOO / ZE1->ZE1_QTDPRO )	
			Else
				ZTRB->REAJO :=  ( _nvval) + ZTRB->REAJO
			EndIf
			
			If _lzera 
				ZTRB->REAJO := - (ZE1->ZE1_CUSTOO / ZE1->ZE1_QTDPRO )
			EndIf
		EndIf 
	
		If _ctipo ==  "Preco"
			If _npval != 0
				ZTRB->PRECOR := ZTRB->PRCMED + ((ZTRB->PRCMED * _npval) / 100 )
				ZTRB->PRCMED := ZTRB->PRCMED + ((ZTRB->PRCMED * _npval) / 100 )
			ElseIf _nval != 0
				ZTRB->PRECOR := _nval 
				ZTRB->PRCMED := _nval 
			Else
				ZTRB->PRECOR := _nval + ZTRB->PRECOR
				ZTRB->PRCMED := _nval + ZTRB->PRCMED			
			EndIf
			
			If _lzera 
				ZTRB->PRECOR := 0
				ZTRB->PRCMED := 0
			EndIf
		EndIf 
	
		If _ctipo ==  "Margem"
			If _npval != 0
				ZTRB->MARGEM := (ZTRB->CUSTO * (_npval/100)) / ( 1 - (_npval/100))
				//Se arredondamento joga margem para baixo vai aumentando para garantir o percentual minimo
				While (ZTRB->MARGEM / ZTRB->PRCMED * 100) < _npval
					ZTRB->MARGEM := ZTRB->MARGEM + 0.01
				EndDo
		
			ElseIf _nval != 0
				ZTRB->MARGEM :=  _nval
			Else
				ZTRB->MARGEM :=  ZTRB->MARGEM + _nvval
			EndIf
			
			If _lzera 
				ZTRB->MARGEM :=  0
			EndIf
		EndIf 
	
		If _ctipo ==  "Embalagens"
		   If _npval > 0
				ZTRB->REAJE := ( _npval * ( ZE1->ZE1_CUSTOE / ZE1->ZE1_QTDPRO ) ) /100 
			ElseIf _nval != 0
				ZTRB->REAJE := _nval - (ZE1->ZE1_CUSTOE / ZE1->ZE1_QTDPRO )
			Else
				ZTRB->REAJE :=  ( _nvval ) + ZTRB->REAJE
			EndIf

			If _lzera 
				ZTRB->REAJE := -(ZTRB->CUSTOE / ZTRB->QTDPRO )
			EndIf
		EndIf 
	
		If _ctipo ==  "Outros"
			If _npval > 0
				ZTRB->REAJU := ( _npval * ( ZE1->ZE1_CUSTOU / ZE1->ZE1_QTDPRO ) ) /100 
			ElseIf _nval != 0
				ZTRB->REAJU := _nval - (ZE1->ZE1_CUSTOU / ZE1->ZE1_QTDPRO )
			Else
				ZTRB->REAJU :=  ( _nvval ) + ZTRB->REAJU
			EndIf
	
			If _lzera 
				ZTRB->REAJU := - (ZTRB->CUSTOU / ZTRB->QTDPRO )
			EndIf
		EndIf
		
		If _ctipo ==  "Custo Corporativo"
			If _npval > 0
				ZTRB->REJCC := ( _npval * ( ZTRB->REJCC ) ) /100 
			ElseIf _nval != 0
				ZTRB->REJCC := _nval 
			Else
				ZTRB->REJCC :=  ( _nvval ) + ZTRB->REJCC
			EndIf
	
			If _lzera 
				ZTRB->REJCC := 0
			EndIf
		EndIf
		
		If _ctipo ==  "Imposto"
			If _npval > 0
				ZTRB->REJIMP := ( _npval * ( ZTRB->REJIMP ) ) /100 
			ElseIf _nval != 0
				ZTRB->REJIMP := _nval 
			Else
				ZTRB->REJIMP :=  ( _nvval ) + ZTRB->REJIMP	
			EndIf
			
			If _lzera 
				ZTRB->REJIMP := 0
			EndIf
		EndIf
		
		If _ctipo ==  "Verba"
			If _npval > 0
				ZTRB->REJVBA := ( _npval * ( ZTRB->REJVBA ) ) /100 
			ElseIf _nval != 0
				ZTRB->REJVBA := _nval 
			Else
				ZTRB->REJVBA :=  ( _nvval ) + ZTRB->REJVBA
			EndIf
	
			If _lzera 
				ZTRB->REJVBA := 0
			EndIf
		EndIf

		_ncustoop		:=	ZE1->ZE1_CUSTOO + (ZTRB->REAJO * ZE1->ZE1_QTDPRO)  
		_ncustopr		:= 	ZE1->ZE1_CUSTOL + (ZTRB->REAJL * ZE1->ZE1_QTDPRO)
		_ncustopr		+= 	ZE1->ZE1_CUSTOE + (ZTRB->REAJE * ZE1->ZE1_QTDPRO) 	
		_ncustopr		+= 	ZE1->ZE1_CUSTOI + (ZTRB->REAJI * ZE1->ZE1_QTDPRO)
		_ncustopr		+= 	ZE1->ZE1_CUSTOU + (ZTRB->REAJU * ZE1->ZE1_QTDPRO)

		ZTRB->CUSTO	    := Round(((_ncustopr + _ncustoop + ZTRB->REJCC+ZTRB->REJIMP+ZTRB->REJVBA) / ZE1->ZE1_QTDPRO),2)
		ZTRB->CUSTOP	:= Round((_ncustopr),2)
			
		If _ctipo ==  "Preco"
			ZTRB->MARGEM := ZTRB->PRECOR - ZTRB->CUSTO
			ZTRB->MRGP		:= ZTRB->MARGEM / ZTRB->PRCMED * 100
		Else
			ZTRB->PRECOR := ZTRB->CUSTO + ZTRB->MARGEM
			ZTRB->PRCMED := ZTRB->CUSTO + ZTRB->MARGEM 
			ZTRB->MRGP		:= ZTRB->MARGEM / ZTRB->PRCMED * 100 
		EndIf
	EndIf
				
	If !ZE1->( Eof() )
	
		RecLock("ZE1",.F.) 
	
		ZE1->ZE1_REAJL		:= ZTRB->REAJL
		ZE1->ZE1_REAJE		:= ZTRB->REAJE
		ZE1->ZE1_REAJI		:= ZTRB->REAJI
		ZE1->ZE1_REAJF		:= ZTRB->REAJF
		ZE1->ZE1_REAJU		:= ZTRB->REAJU
		ZE1->ZE1_REAJO		:= ZTRB->REAJO
		ZE1->ZE1_PRECOR		:= ZTRB->PRECOR
		ZE1->ZE1_REJCC		:= ZTRB->REJCC
		ZE1->ZE1_REJIMP		:= ZTRB->REJIMP
		ZE1->ZE1_REJVBA		:= ZTRB->REJVBA
		ZE1->ZE1_MARGEM		:= ZTRB->MARGEM 
		
		If ZTRB->COMPOR == 'CADASTRO'
	
			ZE1->ZE1_CUSTOO := ZTRB->CUSTOO
			ZE1->ZE1_CUSTOL := ZTRB->CUSTOL
			ZE1->ZE1_CUSTOE := ZTRB->CUSTOE
			ZE1->ZE1_CUSTOF := ZTRB->CUSTOF
			ZE1->ZE1_CUSTOI := ZTRB->CUSTOI
			ZE1->ZE1_CUSTOU := ZTRB->CUSTOU
			ZE1->ZE1_CUSTOP := ZTRB->CUSTOP
		
		EndIf
	
		ZE1->(MSUnLock())
	EndIf

	ZTRB->( DBSkip() )
EndDo

ZTRB->(DbclearFilter() )
_oBrw:Refresh()

MessageBox("Reajuste realizado com sucesso","Reajuste", 64)

_oDlg2:End()

Return 

/*
===============================================================================================================================
Programa----------: CEST002D
Autor-------------: Alex Walaluer
Data da Criacao---: 06/06/2016
Descrição---------: Grava tabela de precos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function CEST002D()

Local _lLimpaTabPreco:=.F.
Local _cAlias   := GetNextAlias()
Local _cTabCopia:="001"
Local _aRecTRB  :={},R
DBSelectArea("ZTRB")

ZTRB->( dbSetFilter( { || AllTrim(ZTRB->MESANO) = "ATUAL" },"AllTrim(ZTRB->MESANO) = 'ATUAL'") )
count to nTot
ZTRB->( DBGoTop() )

If nTot = 0 
   MSGSTOP("Não existe regitros VÁLIDOS para geracao da Tabela de preços.")
EndIf

ProcRegua( nTot )

ZE1->(DBSetOrder(1))

While .not. ZTRB->( Eof() )

   IncProc()
   If !ZE1->(DBSeek(xFilial("ZE1") + 'ATUAL     ' + ZTRB->PRODUTO)) .Or. ZTRB->PRCMED = 0
	  ZTRB->( DBSkip() )
	  Loop
   EndIf

   aAdd(_aRecTRB, ZTRB->(RECNO()) )
   
   ZTRB->( DBSkip() )
	
EndDo

If Len(_aRecTRB) = 0 
   MSGSTOP("Não existe regitros VÁLIDOS para geracao da Tabela de preços.")
   Return .F.
EndIf

ProcRegua( 0 )

DA0->(DBSetOrder(1))
DA1->(DBSetOrder(1))

Begin Transaction   

Begin Sequence

If DA0->(DBSeek(xFilial("DA0")+"001"))

   If DA0->DA0_DATDE = dDatabase
      If MSGYESNO("A tabela de precos já foi gerada hoje deseja APAGA-LA e gerar novamente?")
         _lLimpaTabPreco:=.T.
      EndIf
   EndIf

   If !DA0->(RecLock("DA0",.F.,,.T.))
      MSGSTOP("NÃO foi possivel atualizar a tabela de precos porque esta em uso por outro usuario.")
      BREAK
   EndIf

   If !_lLimpaTabPreco
      _cQuery := " SELECT MAX(DA0_CODTAB)	AS PROX_COD FROM "+ RetSqlName("DA0") +" DA0 "
      _cQuery += " WHERE DA0.DA0_FILIAL = '"+xFilial("DA0")+"' AND DA0.D_E_L_E_T_ = ' ' "
      If(Select(_cAlias) > 0 , (_cAlias)->( DBCloseArea() ) ,)
	  _cQuery := ChangeQuery(_cQuery)
		MPSysOpenQuery(_cQuery,_cAlias)

      _cTabCopia:= StrZero( ( Val((_cAlias)->PROX_COD) + 1 ) ,3)

   EndIf
   
   If DA1->(DBSeek(xFilial("DA0")+"001"))

      While DA1->(DBSeek(xFilial("DA0")+"001"))

         IncProc("Fazendo copia da Tab atual...")

         DA1->(RecLock("DA1",.F.))
         If _lLimpaTabPreco
            DA1->(DBDELETE())
         Else
            DA1->DA1_CODTAB:=_cTabCopia
         EndIf
         DA1->(MSUnLock())
      EndDo

   EndIf

   If _lLimpaTabPreco
      DA0->(DBDELETE())
      DA0->(MSUnLock())
   Else
      DA0->DA0_CODTAB:=_cTabCopia
   EndIf

EndIf

ProcRegua( Len(_aRecTRB) )

DA0->(RecLock("DA0",.T.))
DA0->DA0_FILIAL:=xFilial("DA0")
DA0->DA0_CODTAB:="001"
DA0->DA0_DESCRI:="TABELA DE PRECOS"
DA0->DA0_DATDE :=dDatabase
DA0->DA0_HORADE:="00:00"
DA0->DA0_DATATE:=(dDatabase+30)
DA0->DA0_HORATE:="23:59"
DA0->DA0_TPHORA:="1"
DA0->DA0_ATIVO :="1"
	
For R := 1 TO Len(_aRecTRB)

   IncProc("Gerando tabela de preco...")
   ZTRB->( DBGoTo(_aRecTRB[R]) )

   DA1->(RecLock("DA1",.T.))                                  
   DA1->DA1_FILIAL:=xFilial("DA1")
   DA1->DA1_ITEM  :=StrZero(R,4)
   DA1->DA1_CODTAB:="001"
   DA1->DA1_CODPRO:=ZTRB->PRODUTO
   DA1->DA1_PRCVEN:=ZTRB->PRCMED
   DA1->DA1_ATIVO :="1"
   DA1->DA1_TPOPER:="4"
   DA1->DA1_QTDLOT:=999999.99
   DA1->DA1_INDLOT:="000000000999999.99"
   DA1->DA1_MOEDA :=1
   DA1->DA1_DATVIG:=_dData
   DA1->DA1_PRCMAX:=(ZTRB->PRCMED*_nMaximo)
   DA1->DA1_I_PRMP:=(ZTRB->PRCMED*_nMinimo)
   DA1->(MSUnLock())
	
Next

DA0->(MSUnLock())//Destrava a capa do Registro gravado

If !_lLimpaTabPreco .And. DA0->(DBSeek(xFilial("DA0")+_cTabCopia))
   DA0->(MSUnLock())//Destrava a capa do Registro copiado
EndIf

MessageBox("Tabela de preços gravada com sucesso","Tabela de preços", 64)

End Sequence

End Transaction

ZTRB->(DbclearFilter() )
ZTRB->( DBGoTop() )

Return 
