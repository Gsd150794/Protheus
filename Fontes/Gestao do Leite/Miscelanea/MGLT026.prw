/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |27/10/2020| Chamado 34509. Validação para gerar evento apenas quando produtor tiver movimento no Mix destino.
Lucas Borges  |05/11/2020| Chamado 34509. Retirado filtro de setor e linha. Basta ter entregue leite no período.
Lucas Borges  |29/12/2020| Chamado 35123. Retirada função UCFG001.
===============================================================================================================================
*/

#Include "TOTVS.ch"  

/*
===============================================================================================================================
Programa----------: MGLT026
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Rotina que possibilita gerar o complemento de pagamento a ser pago no próximo Mix
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGLT026

Local _aCores      := {}

Private cAlias		:= "ZZD"
Private cCadastro	:= "Complemento de Pagamento - Próximo Mix"
Private aRotina		:= MenuDef()
Private _cCodigo		:= ""

_aCores := {{"ZZD_NRREGE == 0",'ENABLE'} ,;	//INCLUIDO SEM NENHUM CANCELAMENTO
{"ZZD_NRREGI == ZZD_NRREGE"  ,'DISABLE'},; //TOTALMENTE CANCELADO
{"ZZD_NRREGI > ZZD_NRREGE"   ,'BR_AZUL'}}  //CANCELADO PARCIALMENTE

mBrowse(6,1,22,75,cAlias,,,,,,_aCores)

Return               

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 08/10/2018
Descrição---------: Utilizacao de Menu Funcional
Parametros--------: aRotina
					1. Nome a aparecer no cabecalho
					2. Nome da Rotina associada
					3. Reservado
					4. Tipo de Transa‡„o a ser efetuada:
						1 - Pesquisa e Posiciona em um Banco de Dados
						2 - Simplesmente Mostra os Campos
						3 - Inclui registros no Bancos de Dados
						4 - Altera o registro corrente
						5 - Remove o registro corrente do Banco de Dados
						6 - Altera determinados campos sem incluir novos Regs
					5. Nivel de acesso
					6. Habilita Menu Funcional
Retorno-----------: Array com opcoes da rotina
===============================================================================================================================
*/
Static Function MenuDef()

Local aRotina := {	{ "Pesquisar"			, "AxPesqui" 		, 0 , 1 } ,;
					{ "Visualizar"			, "AxVisual" 		, 0 , 2 } ,;
					{ "Incluir"				, "U_MGLT026T(1)" 	, 0 , 3 } ,;
					{ "Alterar"				, "U_MGLT026T(2)" 	, 0 , 4 } ,;
					{ "Excluir"				, "U_MGLT026T(3)"	, 0 , 5 } ,;
					{ "Legenda"				, "U_MGLT026E()" 	, 0 , 6 } ,;
					{ "Dados Complemento"	, "U_AGLT026Z()"	, 0 , 8 } }

Return( aRotina )

/*
===============================================================================================================================
Programa----------: AGLT026Z
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 01/02/2011
Descrição---------: Funcao desenvolvida para possibilitar a verificacao dos dados por produtor que foram gerados os complementos 
						de pagamento, por codigo de complemento de pagamento.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT026Z

//=======================================================
//Efetua backup das variaveis aRotina e cCadastro para 
//chamar a nova mbrowse.                               
//=======================================================
Local _aBkRotina    := aRotina
Local _cBkCadast    := cCadastro
Local _cAlias       := "ZZG"     
Local _aCores       := {}

Private _cCondicao  := ""    

Private cCadastro   := "REGISTROS DO COMPLEMENTO DE PAGAMENTO"
Private aRotina     := {}  

_cCondicao  := "ZZG_CODIGO == '" + ZZD->ZZD_CODIGO + "'"                                    

DBSelectArea(_cAlias)
(_cAlias)->(DBSetOrder(1))

set filter to  &(_cCondicao)   

aAdd(aRotina,{OemToAnsi("Pesquisar" )        ,'AxPesqui'      ,0,1})
aAdd(aRotina,{OemToAnsi("Visualizar")        ,'AxVisual'      ,0,2})
aAdd(aRotina,{OemToAnsi("Legenda"   )		  ,'U_MGLT026D()'    ,0,3})   
      
_aCores := {{"ZZG_STATUS == '1'",'ENABLE'} ,;     //INCLUIDO    
           {"ZZG_STATUS == '2'",'DISABLE'}}      //EXCLUIDO
 
mBrowse(6,1,22,75,_cAlias,,,,,,_aCores)     

dbClearFilter()

/*
//===============================================
//Restaura as variaveis de controle da mbrowse.
//===============================================
*/
aRotina  := _aBkRotina
cCadastro:= _cBkCadast

Return 

/*
===============================================================================================================================
Programa----------: MGLT026T
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 13/01/2011
Descrição---------: Tela desenvolvida para possibilitar a realizacoes das operacoes de inclusao,alteracao e cancelamento do 
						complemento de pagamento.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGLT026T(_nOperac)

Local _oCbOperac
Local _oGLinFin
Local _oGLinIni
Local _oGLjProdFi
Local _oGLjProdIn
Local _oGMixDest
Local _oGMixOrig
Local _oGProdFin
Local _oGProdIni    
Local _oGProdFora
Local _oGSetor
Local _oGVlrRepor
Local _oSay1
Local _oSay10 
Local _oSay11
Local _oSay12
Local _oSay2
Local _oSay3
Local _oSay4
Local _oSay5
Local _oSay6
Local _oSay7
Local _oSay8
Local _oSay9
Local _oSetor     
Local _oGNumero      
Local _cDescSet    := IIf(_nOperac == 1,"",Posicione("ZL2",1,xFilial("ZL2") + ZZD->ZZD_SETOR,"ZL2->ZL2_DESCRI"))
Local _lInclui      := IIf(_nOperac == 1,.T.,.F.) 
Local _lIncExc      := IIf(_nOperac == 1 .Or. _nOperac == 3,.T.,.F.)
Local _oFont12b

Private oSDadMixOr 
Private oSDadMixDe  
Private _nContReg  := 0    
Private _sDtInic,_sDtFin,_sDtDesIni,_sDtDesFin                
Private cGSetor    := IIf(_nOperac == 1,Space(06),ZZD->ZZD_SETOR) 
Private cGProdIni  := IIf(_nOperac == 1,Space(06),ZZD->ZZD_PROINI)
Private cGProdFin  := IIf(_nOperac == 1,Space(06),ZZD->ZZD_PROFIN)
Private cGMixOrig  := IIf(_nOperac == 1,Space(06),ZZD->ZZD_MIXORI)
Private cGMixDest  := IIf(_nOperac == 1,Space(06),ZZD->ZZD_MIXDES)
Private cGLjProdIn := IIf(_nOperac == 1,Space(04),ZZD->ZZD_LOJINI)
Private cGLjProdFi := IIf(_nOperac == 1,Space(04),ZZD->ZZD_LOJFIN)
Private cGLinIni   := IIf(_nOperac == 1,Space(06),ZZD->ZZD_LININI)
Private cGLinFin   := IIf(_nOperac == 1,Space(06),ZZD->ZZD_LINFIN)     
Private cGVlrRepor := IIf(_nOperac == 1,0,ZZD->ZZD_VALOR)    
Private cCbOperac  := IIf(_nOperac == 1,'Incluir',IIf(_nOperac == 2,'Alterar','Cancelar'))
Private cGNumero   := IIf(_nOperac == 1,GETSXENUM("ZZD","ZZD_CODIGO"),ZZD->ZZD_CODIGO) 
Private cGProdFora := IIf(_nOperac == 1,Space(1600),ZZD->ZZD_PROOUT) 
Private cGProdFor2 := IIf(_nOperac == 1,Space(1600),ZZD->ZZD_PROOU2) 
Private _cDadMixOr := IIf(_nOperac == 1,"",MGLT026M(ZZD->ZZD_MIXORI,1))
Private _cDadMixDe := IIf(_nOperac == 1,"",MGLT026M(ZZD->ZZD_MIXDES,2))   
   
Static oDlg                

Define Font _oFont12b   Name "Courier New"       Size 0,-12 Bold  // Tamanho 12 Negrito

//================================================================
//Caso o usuario queira fazer uma alteracao de um complemento   
//que foi totalmente baixado isto nao sera possivel diante disto
//ele tera que realizar a insercao de um novo complemento de    
//pagametno.                                                    
//================================================================
If _nOperac == 2 

	If ZZD->ZZD_NRREGE == ZZD->ZZD_NRREGI  
		MsgStop("Não é possível realizar a alteração do complemento de pagamento: " + ZZD->ZZD_CODIGO + ;
				"Pois o mesmo encontra-se totalmente cancelado, diante disso favor inserir um novo complemento de pagamento.","MGLT02601")
	 	Return
	EndIf

EndIf 

   DEFINE MSDIALOG oDlg TITLE "COMPLEMENTO DE PAGAMENTO - PRÓXIMO MIX" FROM 000, 000  TO 400, 600 COLORS 0, 16777215 PIXEL 
  	//Comanando para impedir o uso da tecla ESC para fechar a janela
	oDlg:LESCCLOSE := .F.
  
	@ 041, 014 Say _oSay11 PROMPT "Numero:" SIZE 040, 008 OF oDlg COLORS 16711680, 16777215 PIXEL
    @ 041, 054 MSGET _oGNumero VAR cGNumero SIZE 040, 008 OF oDlg COLORS 0, 16777215 WHEN .F. PIXEL 
        
    @ 055, 014 Say _oSay10 PROMPT "Operação:" SIZE 025, 008 OF oDlg COLORS 16711680, 16777215 PIXEL
    @ 055, 054 MSCOMBOBOX _oCbOperac VAR cCbOperac ITEMS {"Incluir","Alterar","Cancelar"} SIZE 040, 010 OF oDlg COLORS 0, 16777215 PIXEL  WHEN .F.     

    @ 069, 014 Say _oSay1 PROMPT "Mix de Origem:" SIZE 040, 008 OF oDlg COLORS 16711680, 16777215 PIXEL
    @ 069, 054 MSGET _oGMixOrig VAR cGMixOrig SIZE 040, 008 OF oDlg VALID IIf(!Empty(cGMixOrig),MGLT026V(cGMixOrig,1),.T.) COLORS 0, 16777215 F3 "ZLE_01" WHEN _lInclui PIXEL
    @ 069, 112 Say oSDadMixOr PROMPT _cDadMixOr SIZE 175, 008 OF oDlg COLORS 0, 16777215 FONT _oFont12b PIXEL  
    
    @ 083, 014 Say _oSay2 PROMPT "Mix de Destino:" SIZE 040, 008 OF oDlg COLORS 16711680, 16777215 PIXEL
    @ 083, 054 MSGET _oGMixDest VAR cGMixDest SIZE 040, 008 OF oDlg VALID IIf(!Empty(cGMixDest),MGLT026V(cGMixDest,2),.T.) COLORS 0, 16777215 F3 "ZLE_01" WHEN _lInclui PIXEL
    @ 083, 112 Say oSDadMixDe PROMPT _cDadMixDe SIZE 175, 008 OF oDlg COLORS 0, 16777215 FONT _oFont12b PIXEL
    
    @ 097, 014 Say _oSetor PROMPT "Setor:" SIZE 025, 008 OF oDlg COLORS 16711680, 16777215 PIXEL
    @ 097, 054 MSGET _oGSetor VAR cGSetor SIZE 040, 008 OF oDlg VALID IIf(!Empty(cGSetor),IIf(U_VSetor(.T.),Eval({|| _cDescSet:= Posicione("ZL2",1,xFilial("ZL2") + cGSetor,"ZL2->ZL2_DESCRI")},oSDescSet:Refresh()),.F.),.T.) COLORS 0, 16777215 F3 "ZL2_01" WHEN _lInclui PIXEL
    @ 097, 112 Say oSDescSet PROMPT _cDescSet SIZE 175, 008 OF oDlg COLORS 0, 16777215 FONT _oFont12b PIXEL
    
    @ 111, 014 Say _oSay7 PROMPT "Linha Inicial:" SIZE 035, 008 OF oDlg COLORS 0, 16777215 PIXEL
    @ 111, 054 MSGET _oGLinIni VAR cGLinIni SIZE 040, 008 OF oDlg VALID IIf(!Empty(cGLinIni) .And. cGLinIni <> 'ZZZZZZ',ExistCpo("ZL3",cGLinIni),.T.) COLORS 0, 16777215 F3 "ZL3_01" WHEN _lIncExc PIXEL
    @ 111, 112 Say _oSay8 PROMPT "Linha Final:" SIZE 029, 008 OF oDlg COLORS 16711680, 16777215 PIXEL
    @ 111, 144 MSGET _oGLinFin VAR cGLinFin SIZE 040, 008 OF oDlg VALID IIf(!Empty(cGLinFin) .And. cGLinFin <> 'ZZZZZZ',ExistCpo("ZL3",cGLinFin),.T.) COLORS 0, 16777215 F3 "ZL3_01" WHEN _lIncExc PIXEL
    
    @ 125, 014 Say _oSay3 PROMPT "Produtor De:" SIZE 034, 008 OF oDlg COLORS 0, 16777215 PIXEL
    @ 125, 054 MSGET _oGProdIni VAR cGProdIni SIZE 040, 008 OF oDlg VALID IIf(!Empty(cGProdIni) .And. cGProdIni <> 'ZZZZZZ',ExistCpo("SA2",cGProdIni),.T.) COLORS 0, 16777215 F3 "SA2_L4" WHEN _lIncExc PIXEL
    @ 125, 112 Say _oSay4 PROMPT "Loja De:" SIZE 025, 008 OF oDlg COLORS 0, 16777215 PIXEL
    @ 125, 144 MSGET _oGLjProdIn VAR cGLjProdIn SIZE 040, 008 OF oDlg VALID IIf(!Empty(cGProdIni) .And. cGProdIni <> 'ZZZZZZ' .And. !Empty(cGLjProdIn) .And. cGLjProdIn <> 'ZZZZ',ExistCpo("SA2",cGProdIni + cGLjProdIn),.T.) COLORS 0, 16777215 WHEN _lIncExc PIXEL
    
    @ 139, 014 Say _oSay5 PROMPT "Produtor Ate:" SIZE 034, 008 OF oDlg COLORS 16711680, 16777215 PIXEL
    @ 139, 054 MSGET _oGProdFin VAR cGProdFin SIZE 040, 008 OF oDlg VALID IIf(!Empty(cGProdFin) .And. cGProdFin <> 'ZZZZZZ',ExistCpo("SA2",cGProdFin),.T.) COLORS 0, 16777215 F3 "SA2_L4" WHEN _lIncExc PIXEL
    @ 139, 112 Say _oSay6 PROMPT "Loja Ate:" SIZE 034, 008 OF oDlg COLORS 16711680, 16777215 PIXEL    
    @ 139, 144 MSGET _oGLjProdFi VAR cGLjProdFi SIZE 040, 008 OF oDlg VALID IIf(!Empty(cGProdFin) .And. cGProdFin <> 'ZZZZZZ' .And. !Empty(cGLjProdFi) .And. cGLjProdFi <> 'ZZZZ',ExistCpo("SA2",cGProdFin + cGLjProdFi),.T.) COLORS 0, 16777215 WHEN _lIncExc PIXEL
    
    @ 153, 014 Say _oSay9 PROMPT "Valor a repor:" SIZE 036, 008 OF oDlg COLORS 16711680, 16777215 PIXEL
    @ 153, 054 MSGET _oGVlrRepor VAR cGVlrRepor SIZE 040, 008 OF oDlg PICTURE "@E 99.9999" COLORS 0, 16777215 WHEN IIf(_nOperac == 1 .Or. _nOperac == 2,.T.,.F.) PIXEL            
    
    @ 167, 014 Say _oSay10 PROMPT "Produt.Fora 1:" SIZE 035, 008 OF oDlg COLORS 0, 16777215 PIXEL
    @ 167, 054 MSGET _oGProdFora VAR cGProdFora SIZE 231, 008 OF oDlg COLORS 0, 16777215 WHEN _lInclui PIXEL

	@ 181, 014 Say _oSay12 PROMPT "Produt.Fora 2:" SIZE 035, 008 OF oDlg COLORS 0, 16777215 PIXEL
    @ 181, 054 MSGET _oGProdFor2 VAR cGProdFor2 SIZE 231, 008 OF oDlg COLORS 0, 16777215 WHEN _lInclui PIXEL

    ACTIVATE MSDIALOG oDlg CENTERED ON INIT EnchoiceBar(oDlg,{||nopc:=1,IIf(MGLT026K(),IIf(MGLT026G(),oDlg:End(),),)}, {||nopc:=2,oDlg:End(),RollBackSX8()},,)   	    
    	    
Return              

/*
===============================================================================================================================
Programa----------: MGLT026T
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 13/01/2011
Descrição---------: Efetua a validacao para verificar o fornecimento correto do Mix de destino e de origem.
Parametros--------: _cCodMix - Codigo do Mix, _cTpMix - 1 == Mix de Origem e 2 == Mix de Destino 
Retorno-----------: _lRet - lógico validando ou não o campo de Mix
===============================================================================================================================
*/
Static Function MGLT026V(_cCodMix,_cTpMix)       
 
Local _nCountRec:= 0        
Local _lRet    := .T.  

Private _cAliasZLE := GetNextAlias()  

//========================================================
// Chama para funcao filtrar os dado do Mix             
//========================================================
Processa( {||MGLT026Q(1,_cCodMix)}/*bAction*/, "Aguarde..."/*cTitle */, "Filtrando Dados do Mix..."/*cMsg */,.F./*lAbort */)
_nCountRec := _nContReg       
	
If _nCountRec > 0      
		
	(_cAliasZLE)->(DBGoTop())
	  
	//Mix de Origem
	If _cTpMix == 1	     
		_cDadMixOr:= DToC(SToD((_cAliasZLE)->ZLE_DTINI)) + " = " + DToC(SToD((_cAliasZLE)->ZLE_DTFIM))
		//Armazena a data inicial e final do mix de origem para ser utilizada em query futura	 
		_sDtInic  := (_cAliasZLE)->ZLE_DTINI
		_sDtFin   := (_cAliasZLE)->ZLE_DTFIM  
   	//Mix de Destino           
	Else 
		_cDadMixDe	 := DToC(SToD((_cAliasZLE)->ZLE_DTINI)) + " = " + DToC(SToD((_cAliasZLE)->ZLE_DTFIM)) 
		_sDtDesIni   := (_cAliasZLE)->ZLE_DTINI
		_sDtDesFin   := (_cAliasZLE)->ZLE_DTFIM 
	EndIf			     

//Nao foi encontrado nenhum mix de acordo com o codigo fornecido acima 
Else   
	MsgStop("Número do mix inexistente. Favor selecionar/informar um número de mix correto.","MGLT02602")
	_lRet:= .F.	   
EndIf         

(_cAliasZLE)->(DBCloseArea())
	
oSDadMixOr:Refresh()
oSDadMixDe:Refresh()	

Return _lRet      

/*
===============================================================================================================================
Programa----------: MGLT026S
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 30/07/2012
Descrição---------: Efetua a validacao para verificar o fornecimento correto do Mix de destino e de origem.
Parametros--------: _nTipoMix - 1 == Mix de Origem e 2 == Mix de Destino,_cCdMix - Codigo do Mix, _cCdSetor - Codigo do Setor.
Retorno-----------: _lRet - Lógico indicando validação do campo
===============================================================================================================================
*/
Static Function MGLT026S(_nTipoMix,_cCdMix,_cCdSetor)
                              
Local _lRet		:= .T.
Local _cAlias	:= GetNextAlias()
Local _cFiltro	:= "%"

_cFiltro += " AND ZLF_FILIAL = '" + xFilial("ZLF") + "'"
_cFiltro += " AND ZLF_CODZLE = '" + _cCdMix + "'"
_cFiltro += " AND ZLF_SETOR = '" + _cCdSetor + "'"

//=======================================================================
//Validacao no mix de origem, para este mix deve estar fechado o setor.
//=======================================================================
If _nTipoMix == 1
	_cFiltro += " AND ZLF_ACERTO NOT IN ('S','B') "
	_cFiltro += " AND ZLF_STATUS NOT IN ('F','B') "
	
//=======================================================================
//Validacao no mix de destino, para este mix deve estar aberto o setor.
//=======================================================================
Else
	_cFiltro += " AND ZLF_ACERTO IN ('S','B') "
	_cFiltro += " AND ZLF_STATUS IN ('F','B') "
EndIf 

_cFiltro += "%"

BeginSql alias _cAlias
	SELECT COUNT(1) NUMREG
	FROM %Table:ZLF%
	WHERE D_E_L_E_T_ = ' '
	%exp:_cFiltro%	
EndSql     

If _nTipoMix == 1
	If (_cAlias)->NUMREG > 0
		If !MsgYesNo("Mix fornecido incorretamente no campo Mix de Origem. Deseja continuar mesmo com status aberto?.","MGLT02602")
			_lRet:= .F.
		EndIf
	EndIf
Else
	If (_cAlias)->NUMREG > 0
		If !MsgYesNo("Mix fornecido incorretamente no campo Mix de Destino. Deseja continuar mesmo com status fechado?.","MGLT02603")
			_lRet:= .F.
		EndIf
	EndIf
EndIf

//Finaliza a area criada anteriormente
(_cAlias)->(DBCloseArea())

Return _lRet

/*
===============================================================================================================================
Programa----------: MGLT026K
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Efetua a validacao do preenchimento dos dados da tela.	
Parametros--------: Nenhum
Retorno-----------: _lRet - Lógico indicando validação do dos dados
===============================================================================================================================
/*/ 
Static Function MGLT026K()       

Local _lRet:= .T.

If Empty(cGMixOrig) .Or. Empty(cGMixDest) .Or. Empty(cGSetor ) .Or. Empty(cGLinFin) .Or. Empty(cGProdFin) .Or. Empty(cGLjProdFi) 
	MsgStop("O preenchimento dos campos destacados na cor azul é obrigatório!","MGLT02603")
	_lRet:= .F.	   
EndIf         

//Inclusao de complemento de Pagamento
If (cCbOperac == 'Incluir' .Or. cCbOperac == 'Alterar') .And. cGVlrRepor == 0
	MsgStop("Para realizar a operação de inclusão de um complemento de pagamento é necessário o fornecimento do valor a repor por litro de leite.","MGLT02604")
	_lRet:= .F.	  
EndIf

If Val(cGMixOrig) > Val(cGMixDest)  
	MsgStop("O mix de destino tem que ser maior que o mix de origem!","MGLT02605")
	_lRet:= .F.	   
EndIf

If _lRet .And. (At('/',cGProdFora) > 0 .Or. At('/',cGProdFor2) > 0)
	MsgStop("Utilize ; para separar os produtores.","MGLT02619")
	_lRet:= .F.	   
EndIf
 
//Valida mix de origem
If _lRet
	_lRet:= MGLT026S(1,cGMixOrig,cGSetor)
EndIf    

//Valida mix de destino
If _lRet
	_lRet:= MGLT026S(2,cGMixDest,cGSetor)
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: MGLT026G
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Rotina utilizada para realizar a insercao do complemento de pagamento no Mix para faturo pagamento quando o
						mix de destino For fechado.
Parametros--------: Nenhum
Retorno-----------: _lRet - Lógico indicando validação do dos dados
===============================================================================================================================
/*/ 
Static Function MGLT026G

Local _nCountRec   := 0    
Local _lRet       := .T.  

Private _cAliasZL8:= GetNextAlias()

//===============================================================
//Seleciona o evento para geracao/exclusao dos complementos de 
//pagamento aos produtores.                                    
//===============================================================
Processa( {||MGLT026Q(2,"")}/*bAction*/, "Aguarde..."/*cTitle */, "Filtrando o evento para geração do complemento..."/*cMsg */,.F./*lAbort */)
_nCountRec := _nContReg                

//===============================================================
//Somente podera existir um evento de complemento de pagamento 
//por Filial, para que desta forma se passe o codigo correto na
//geracao automatica do complemento.                           
//===============================================================
If _nCountRec == 1                  
	(_cAliasZL8)->(DBGoTop())
	_cCodEvent:= (_cAliasZL8)->ZL8_COD
	_cDesEvent:= (_cAliasZL8)->ZL8_NREDUZ

	//=======================================================
	//Gerando a inclusao de um complemento de pagamento aos
	//Produtores.                                          
	//=======================================================
	If cCbOperac == 'Incluir'
		Processa({||_lRet:=MGLT026P(_cCodEvent,_cDesEvent) },"Aguarde...Processando a inclusão do complemento...")			    

		//===========================================================
		//Gerando o cancelamento de um complemento de pagamento aos
		//Produtores.                                              
		//===========================================================
	ElseIf cCbOperac == 'Cancelar'
		Processa({||_lRet:=MGLT026C(_cCodEvent) },"Aguarde....Processando o cancelamento do complemento...")    
				    
		//==============================================================
		//Efetua a alteracao do valor do complemento gerado, de acordo
		//com os parametros fornecidos na inclusao.                   
		//==============================================================
	Else         
		Processa({||_lRet:=MGLT026A(_cCodEvent) },"Aguarde....Processando o alteração do complemento...") 
	EndIf  
		
//=======================================================
//Problema encontrado no evento cadastrado para geracao
//do complemento de pagamento.                         
//=======================================================
Else   
	MsgStop("Verificar se foi cadastrado algum evento para geração do complemento de pagamento ao Produtor. A de se ressaltar que "+;
			"não poderá ser cadastrado mais de evento para geração do complemento, este evento deve ser cadastrado de acordo com "+;
			"os parâmetros definidos pelo suporte do Leite.","MGLT02606")
   _lRet:= .F.
EndIf		

(_cAliasZL8)->(DBCloseArea())

Return _lRet

/*
===============================================================================================================================
Programa----------: MGLT026P
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Funcao utilizada para gravar na tabela ZLF os dados do complemento de pagamento aos Produtores
Parametros--------: _cCodEvent - Codigo do evento
					  _cDesEvent - Descrição do evento
Retorno-----------: _lRet - Lógico indicando sucesso na gravação
===============================================================================================================================
*/ 
Static Function MGLT026P(_cCodEvent,_cDesEvent)

Local _nCountRec	:= 0
Local _lRet			:= .T.  
Local _nQtdeVolu	:= 0
Local _cFiltro		:= "%"
Local _cMatUsr		:= FWSFAllUsers({RetCodUsr()},{"USR_FILIAL","USR_CODFUNC"})[1][3]+FWSFAllUsers({RetCodUsr()},{"USR_FILIAL","USR_CODFUNC"})[1][4]
Private _cAliaIncl	:= GetNextAlias()
Private _cAliasZLD           

//===================================================================
//Verifica se o status no mix dos produtores selecionados de acordo
//com os parametros informados pelo usuario para constatar senao   
//existir produtor efetivado ou com o status fechado no mix.       
//===================================================================
Processa( {||MGLT026Q(5,"")}/*bAction*/, "Aguarde..."/*cTitle */, "Verificando stadus dos produtores selecionados no Mix..."/*cMsg */,.F./*lAbort */)
_nCountRec := _nContReg   

(_cAliaIncl)->(DBCloseArea())

If _nCountRec == 0     
	_cAliasZLD:= GetNextAlias()      
	
	//============================================================
	//Query utilizada para filtrar os dados da recepcao de leite
	//dos produtores enquadrados nos parametros fornecidos pelo 
	//usuario e sua respectiva recepcao de leite para calculo do
	//valor de complemento de pagamento a ser gerado.
	//============================================================

	//==============================================================
	//Caso o usuario tenha fornecido o codigo de alguns produtores
	//que nao farao parte do complemento de pagamento.            
	//==============================================================
	If Len(AllTrim(cGProdFora)) > 0
		_cFiltro += " AND ZLD.ZLD_RETIRO NOT IN " + FormatIn(cGProdFora,";")
	EndIf
	If Len(AllTrim(cGProdFor2)) > 0
		_cFiltro += " AND ZLD.ZLD_RETIRO NOT IN " + FormatIn(cGProdFor2,";")
	EndIf
	_cFiltro += "%"
	
	BeginSql alias _cAliasZLD
		SELECT ZLD_RETIRO, ZLD_RETILJ, SA2.A2_NOME, ZLD_SETOR, ZL2.ZL2_DESCRI, ZLD_LINROT, ZL3.ZL3_DESCRI, SUM(ZLD_QTDBOM) QTDELEITE
		  FROM %Table:ZLD% ZLD, %Table:SA2% SA2, %Table:ZL2% ZL2, %Table:ZL3% ZL3
		 WHERE ZLD.D_E_L_E_T_ = ' '
		   AND SA2.D_E_L_E_T_ = ' '
		   AND ZL2.D_E_L_E_T_ = ' '
		   AND ZL3.D_E_L_E_T_ = ' '
		   AND SA2.A2_COD = ZLD.ZLD_RETIRO
		   AND SA2.A2_LOJA = ZLD.ZLD_RETILJ
		   AND ZL2.ZL2_FILIAL = ZLD.ZLD_FILIAL
		   AND ZL2.ZL2_COD = ZLD.ZLD_SETOR
		   AND ZL3.ZL3_FILIAL = ZLD.ZLD_FILIAL
		   AND ZL3.ZL3_COD = ZLD.ZLD_LINROT
		   %exp:_cFiltro%
		   AND ZLD.ZLD_FILIAL = %xFilial:ZLD%
		   AND ZLD.ZLD_DTCOLE BETWEEN %exp:_sDtInic% AND %exp:_sDtFin%
		   AND ZLD.ZLD_SETOR = %exp:cGSetor%
		   AND ZLD.ZLD_LINROT BETWEEN %exp:cGLinIni% AND %exp:cGLinFin%
		   AND ZLD.ZLD_RETIRO BETWEEN %exp:cGProdIni% AND %exp:cGProdFin%
		   AND ZLD.ZLD_RETILJ BETWEEN %exp:cGLjProdIn% AND %exp:cGLjProdFi%
		   AND ZLD.ZLD_QTDBOM > 0
		   AND EXISTS (SELECT 1 
			   FROM %Table:ZLD% ZLD2
				WHERE ZLD2.D_E_L_E_T_ = ' '
				AND ZLD2.ZLD_RETIRO = ZLD.ZLD_RETIRO
				AND ZLD2.ZLD_RETILJ = ZLD.ZLD_RETILJ
				AND ZLD2.ZLD_FILIAL = ZLD.ZLD_FILIAL
				AND ZLD2.ZLD_DTCOLE BETWEEN %exp:_sDtDesIni% AND %exp:_sDtDesFin%)
		 GROUP BY ZLD_RETIRO, ZLD_RETILJ, SA2.A2_NOME, ZLD_SETOR, ZL2.ZL2_DESCRI, ZLD_LINROT, ZL3.ZL3_DESCRI
	EndSql

	COUNT TO _nContReg //Contabiliza o numero de registros encontrados pela query     

	_nCountRec := _nContReg
		
	ProcRegua(_nCountRec)  
		
	If _nCountRec > 0                
		
		Begin Transaction
		
			(_cAliasZLD)->(DBGoTop())

			While (_cAliasZLD)->(!Eof())

				IncProc("Inserindo evento no Mix do produtor: " + (_cAliasZLD)->ZLD_RETIRO  + "/" + (_cAliasZLD)->ZLD_RETILJ)

				_nQtdeVolu  += (_cAliasZLD)->QTDELEITE

				RecLock("ZLF", .T.)
					ZLF->ZLF_FILIAL := xFilial("ZLF")
					ZLF->ZLF_CODZLE := cGMixDest
					ZLF->ZLF_VERSAO := '1'
					ZLF->ZLF_SETOR  := (_cAliasZLD)->ZLD_SETOR
					ZLF->ZLF_LINROT := (_cAliasZLD)->ZLD_LINROT
					ZLF->ZLF_A2COD	:= (_cAliasZLD)->ZLD_RETIRO
					ZLF->ZLF_A2LOJA	:= (_cAliasZLD)->ZLD_RETILJ
					ZLF->ZLF_RETIRO := (_cAliasZLD)->ZLD_RETIRO
					ZLF->ZLF_RETILJ := (_cAliasZLD)->ZLD_RETILJ
					ZLF->ZLF_EVENTO := _cCodEvent
					ZLF->ZLF_ENTMIX := "S"
					ZLF->ZLF_DEBCRED:= "C"
					ZLF->ZLF_DTINI  := SToD(_sDtDesIni)
					ZLF->ZLF_DTFIM  := SToD(_sDtDesFin)
					ZLF->ZLF_QTDBOM := (_cAliasZLD)->QTDELEITE
					ZLF->ZLF_TOTAL  := (_cAliasZLD)->QTDELEITE * cGVlrRepor
					ZLF->ZLF_VLRLTR := (ZLF->ZLF_TOTAL/ZLF->ZLF_QTDBOM)
					ZLF->ZLF_ORIGEM := "M"
					ZLF->ZLF_ACERTO := "N"
					ZLF->ZLF_TP_MIX := "L"
					ZLF->ZLF_TIPO   := "L"
					ZLF->ZLF_SEQ	:= u_getSeqZLF(cGMixDest,_cCodEvent,(_cAliasZLD)->ZLD_RETIRO,(_cAliasZLD)->ZLD_RETILJ)
					ZLF->ZLF_STATUS := "A"
					ZLF->ZLF_SEEKCO := cGNumero+"MGLT026"
				ZLF->(MSUnLock())
				(_cAliasZLD)->(DBSkip())
			EndDo

			//==========================================================
			//Efetua a inserção dos itens do complemento de pagamento.
			//==========================================================

			(_cAliasZLD)->(DBGoTop())
			While (_cAliasZLD)->(!Eof())
				RecLock("ZZG",.T.)
					ZZG->ZZG_FILIAL:= xFilial("ZZF")
					ZZG->ZZG_CODIGO:= cGNumero
					ZZG->ZZG_FORNEC:= (_cAliasZLD)->ZLD_RETIRO
					ZZG->ZZG_LJFORN:= (_cAliasZLD)->ZLD_RETILJ
					ZZG->ZZG_A2NOME:= (_cAliasZLD)->A2_NOME
					ZZG->ZZG_LINHA := (_cAliasZLD)->ZLD_LINROT
					ZZG->ZZG_DCLINH:= (_cAliasZLD)->ZL3_DESCRI
					ZZG->ZZG_VALOR := cGVlrRepor
					ZZG->ZZG_VOLUME:= (_cAliasZLD)->QTDELEITE
					ZZG->ZZG_VLRTOT:= (_cAliasZLD)->QTDELEITE * cGVlrRepor 
					ZZG->ZZG_STATUS:= '1'
				ZZG->(MSUnLock())
				(_cAliasZLD)->(DBSkip())
			EndDo

			//=========================================================
			//Efetua a inserção dos dados na tabela ZZD referente ao 
			//complemento efetuado.
			//=========================================================
			RecLock("ZZD",.T.)
				ZZD->ZZD_FILIAL:= xFilial("ZZD")
				ZZD->ZZD_CODIGO:= cGNumero
				ZZD->ZZD_MIXORI:= cGMixOrig
				ZZD->ZZD_MIXDES:= cGMixDest
				ZZD->ZZD_SETOR := cGSetor
				ZZD->ZZD_LININI:= cGLinIni
				ZZD->ZZD_LINFIN:= cGLinFin
				ZZD->ZZD_PROINI:= cGProdIni
				ZZD->ZZD_PROFIN:= cGProdFin
				ZZD->ZZD_LOJINI:= cGLjProdIn
				ZZD->ZZD_LOJFIN:= cGLjProdFi
				ZZD->ZZD_VALOR := cGVlrRepor
				ZZD->ZZD_VOLUME:= _nQtdeVolu
				ZZD->ZZD_VLRTOT:= _nQtdeVolu * cGVlrRepor
				ZZD->ZZD_NRREGI:= _nCountRec   
				ZZD->ZZD_NRREGE:= 0     
				ZZD->ZZD_DATA  := Date()
				ZZD->ZZD_USERIN:= _cMatUsr
				ZZD->ZZD_USERAC:= ""
				ZZD->ZZD_PROOUT:= cGProdFora
				ZZD->ZZD_PROOU2:= cGProdFor2
			ZZD->(MSUnLock())       
			
			If (__lSX8)
				ConfirmSX8()
			EndIf
		End Transaction
			
		//==========================================================
		//Nao existem registros selecionados na recepcao de Leite.
		//==========================================================
	Else
		MsgStop("Não foram encontrados registros na recepção de leite, para gerar o complemento de pagamento." +;
				"Favor checar se os parâmetros de filtro foram informados corretamente.","MGLT02607")
		_lRet:= .F.	 
	EndIf
	(_cAliasZLD)->(DBCloseArea())
		
	//====================================================================
	//Existem produtores com o status fechado ou efetivado, inclusao nao
	//permitida.                                                        
	//====================================================================
Else
	MsgStop("Existe(m) produtor(es) que consta(m) com o seu status no mix como efetivado ou fechado. "+;
			"Desta forma não será gerado o complemento de pagamento, favor alterar no mix o status dos produtores para aberto antes de realizar esta operação.","MGLT02608")
	_lRet:= .F.	 
EndIf		

Return _lRet   

/*
===============================================================================================================================
Programa----------: MGLT026Q
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Rotina desenvolvida para possibilitar o armazenamento de todas as query executas no fonte MGLT026
Parametros--------: _nQuery - numero da query a ser executada		
					  _cCodMix - Codigo do Mix na validacao do GET(origem ou destino)
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
Static Function MGLT026Q(_nQuery,_cCodMix,_cCodEvent) 

Local _cFiltro := "%"

Do Case    
        	
	//==============================================================
	//Query utilizada para filtrar os dados do Mix na validacao do
	//campos de mix de origem e destino.                          
	//==============================================================
	Case _nQuery == 1
		BeginSql Alias _cAliasZLE
			SELECT ZLE_DTINI, ZLE_DTFIM, ZLE_STATUS
			  FROM %Table:ZLE% ZLE
			 WHERE D_E_L_E_T_ = ' '
			   AND ZLE_FILIAL = %xFilial:ZLE%
			   AND ZLE_COD = %exp:_cCodMIX%
		EndSql

	//==================================================================
	//Query utilizada para selecionar o evento de credito a ser gerado
	//para o complemento de pagamento.                                
	//==================================================================
	Case _nQuery == 2
    	BeginSql Alias _cAliasZL8
			SELECT ZL8.ZL8_COD, ZL8.ZL8_NREDUZ
			  FROM %Table:ZL8% ZL8
			 WHERE D_E_L_E_T_ = ' '
			   AND ZL8_FILIAL = %xFilial:ZL8%
			   AND ZL8.ZL8_COMPGT = 'S'
			   AND ZL8.ZL8_DEBCRE = 'C'
			   AND ZL8.ZL8_PERTEN = 'P'
			   AND ZL8.ZL8_TPEVEN = 'A'
			   AND ZL8.ZL8_IMPNF = 'S'
			   AND ZL8.ZL8_MIX = 'S'
			   AND ZL8.ZL8_FORMUL = '.F.'
			   AND ZL8.ZL8_CONDIC = '.F.'
			   AND ZL8.ZL8_SB1COD <> ' '
			   AND ZL8.ZL8_MSBLQL <> '1'
		EndSql
	    
	//=========================================================
	//Deleta os registro de complemento de pagamento conforme
	//parametros fornecidos pelo usuario.                    
	//=========================================================
	Case _nQuery == 4 	 
		BeginSql alias _cAliasExc
			SELECT R_E_C_N_O_ RECNOZLF, ZLF_QTDBOM QTDELEITE, ZLF_ACERTO, ZLF_STATUS, ZLF_A2COD, ZLF_A2LOJA, ZLF_LINROT
			  FROM %Table:ZLF% ZLF
			 WHERE D_E_L_E_T_ = ' '
			   AND ZLF_FILIAL = %xFilial:ZLF%
			   AND ZLF_CODZLE = %exp:cGMixDest%
			   AND ZLF_SETOR = %exp:cGSetor%
			   AND ZLF_LINROT BETWEEN %exp:cGLinIni% AND %exp:cGLinFin%
			   AND ZLF_RETIRO BETWEEN %exp:cGProdIni% AND %exp:cGProdFin%
			   AND ZLF_RETILJ BETWEEN %exp:cGLjProdIn% AND %exp:cGLjProdFi%
			   AND ZLF_SEEKCO = %exp:cGNumero+"MGLT026"%
		EndSql
	
	//==================================================================
	//Verifica no momento da inclusao se existem produtores com o     
	//status efetivado ou fechado para nao deixar realizar a inclusao 
	//do complemento de pagamento antes de deixar o status do mix     
	//aberto.                                                         
	//==================================================================
	Case _nQuery == 5
		//==============================================================
		//Caso o usuario tenha fornecido o codigo de alguns produtores
		//que nao farao parte do complemento de pagamento.            
		//==============================================================
		If Len(AllTrim(cGProdFora)) > 0
			_cFiltro += " AND ZLF.ZLF_RETIRO NOT IN " + FormatIn(cGProdFora,";")
		EndIf
		_cFiltro += "%"
		
		BeginSql alias _cAliaIncl
			SELECT ZLF.ZLF_A2COD, ZLF.ZLF_A2LOJA
			  FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8
			 WHERE ZLF.D_E_L_E_T_ = ' '
			   AND ZL8.D_E_L_E_T_ = ' '
			   AND ZL8.ZL8_FILIAL = ZLF.ZLF_FILIAL
			   AND ZL8.ZL8_COD = ZLF.ZLF_EVENTO
			   AND ZLF.ZLF_FILIAL = %xFilial:ZLF%
			   AND ZL8.ZL8_PERTEN = 'P'
			   AND ZLF.ZLF_STATUS IN ('F', 'E') 
			   %exp:_cFiltro%
			   AND ZLF.ZLF_CODZLE = %exp:cGMixDest%
			   AND ZLF.ZLF_SETOR = %exp:cGSetor%
			   AND ZLF.ZLF_LINROT BETWEEN %exp:cGLinIni% AND %exp:cGLinFin%
			   AND ZLF.ZLF_RETIRO BETWEEN %exp:cGProdIni% AND %exp:cGProdFin%
			   AND ZLF.ZLF_RETILJ BETWEEN %exp:cGLjProdIn% AND %exp:cGLjProdFi%
		EndSql
EndCase

COUNT TO _nContReg //Contabiliza o numero de registros encontrados pela query

Return 

/*
===============================================================================================================================
Programa----------: MGLT026Q
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Retorna a data inicial e final do mix de origem e destino para visualizacao na alteracao e cancelmento.
Parametros--------: _cCodMix - Codigo do Mix
						 _cTpMix - 1 == Mix de Origem  2 == Mix de Destino        
Retorno-----------: _cDescri - data inicial e final do mix 
===============================================================================================================================
*/ 
Static Function MGLT026M(_cCodMix,_cTpMix)   

Local _nCountRec   := 0            
Local _cDescri     := ""

Private _cAliasZLE:= GetNextAlias()

//========================================================
// Chama para funcao filtrar os dado do Mix             
//========================================================
Processa( {||MGLT026Q(1,_cCodMix)}/*bAction*/, "Aguarde..."/*cTitle */, "Filtrando dados do Mix..."/*cMsg */,.F./*lAbort */)
_nCountRec := _nContReg       
	
If _nCountRec > 0      
		
	(_cAliasZLE)->(DBGoTop())
  
	//Mix de Origem
	If _cTpMix == 1	
		_cDescri:= DToC(SToD((_cAliasZLE)->ZLE_DTINI)) + " = " + DToC(SToD((_cAliasZLE)->ZLE_DTFIM))
		//Armazena a data inicial e final do mix de origem para ser utilizada em query futura	 
		_sDtInic  := (_cAliasZLE)->ZLE_DTINI
		_sDtFin   := (_cAliasZLE)->ZLE_DTFIM  				
	//Mix de Destino           
	Else 			
		_cDescri:= DToC(SToD((_cAliasZLE)->ZLE_DTINI)) + " = " + DToC(SToD((_cAliasZLE)->ZLE_DTFIM)) 
		_sDtDesIni   := (_cAliasZLE)->ZLE_DTINI
		_sDtDesFin   := (_cAliasZLE)->ZLE_DTFIM 					
	EndIf				     
  						
EndIf         

(_cAliasZLE)->(DBCloseArea())

Return _cDescri

/*
===============================================================================================================================
Programa----------: MGLT026E
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Legenda do browse principal (ZZE)
Parametros--------: Nenhum   
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
User Function MGLT026E()

BrwLegenda("Legenda","Status dos Complementos",{{"ENABLE","Complemento sem cancelamento"},;
														{"DISABLE","Complemento tatalmente cancelado"},;
														{"BR_AZUL","Complemento parcialmente cancelado"}})

Return(.T.)       

/*
===============================================================================================================================
Programa----------: MGLT026D
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Legenda do browse auxiliar (ZZG)
Parametros--------: Nenhum   
Retorno-----------: Nenhum
===============================================================================================================================
/*/ 
User Function MGLT026D

BrwLegenda("Legenda","Status dos Complementos",{{"ENABLE","Complemento incluído"},{"DISABLE","Complemento cancelado"}})

Return(.T.)

/*
===============================================================================================================================
Programa----------: MGLT026C
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Processa o cancelamento dos registros de complemento de pagamento.
Parametros--------: _cCodEvent - codigo do evento  
Retorno-----------: _lRet - Lógico indicando sucesso do cancelamento
===============================================================================================================================
*/       
Static Function MGLT026C(_cCodEvent) 

Local _nCountRec:= 0    
Local _lRet		:= .T. 
Local _nVolLeite:= 0
Local _nVlrTotal:= 0
Local _cMatUsr	:= FWSFAllUsers({RetCodUsr()},{"USR_FILIAL","USR_CODFUNC"})[1][3]+FWSFAllUsers({RetCodUsr()},{"USR_FILIAL","USR_CODFUNC"})[1][4]

Private _cAliasExc 
Private _cAliaIncl:= GetNextAlias() 

//===================================================================
//Verifica se o status no mix dos produtores selecionados de acordo
//com os parametros informados pelo usuario para constatar senao   
//existir produtor efetivado ou com o status fechado no mix.       
//===================================================================
Processa( {||MGLT026Q(5,"")}/*bAction*/, "Aguarde..."/*cTitle */, "Verificando o status dos produteos selecionados no Mix..."/*cMsg */,.F./*lAbort */)
_nCountRec := _nContReg   

(_cAliaIncl)->(DBCloseArea())

If _nCountRec == 0 

	_cAliasExc:= GetNextAlias()    
	                                
	//==============================================================
	//Query para realizar o cancelamento do complemento de acorfdo
	//com os parametros informados pelo usuário.                  
	//==============================================================
	Processa( {||MGLT026Q(4,"","")}/*bAction*/, "Aguarde..."/*cTitle */, "Selecionando registros para realizar a exclusão..."/*cMsg */,.F./*lAbort */)
	_nCountRec := _nContReg      
	
	ProcRegua(_nCountRec) 
	
	If _nCountRec > 0   
	
		_nCountRec:= 0                     
	
		Begin Transaction                       
	
			(_cAliasExc)->(DBGoTop())
		
			While (_cAliasExc)->(!Eof())   
		
				IncProc()		                         
				                         
				DBSelectArea("ZLF")	                         
				ZLF->(DBGoTo((_cAliasExc)->RECNOZLF))
				
				If ZLF->ZLF_EVENTO == _cCodEvent .And. cGNumero+"MGLT026" $ ZLF->ZLF_SEEKCO  
					_nVolLeite += ZLF->ZLF_QTDBOM
					_nVlrTotal += ZLF->ZLF_TOTAL
				    
					RecLock("ZLF",.F.)
					dbDelete()     
					ZLF->(MSUnLock())	
					
					_nCountRec++
				Else
					MsgStop("Problema encontrado no cancelamento do complemento de pagamento. Favor comunicar ao departamento de informática de "+;
							"tal problema encontrado, o erro ocorreu no R_E_C_N_O_ : " + AllTrim(Str((_cAliasExc)->RECNOZLF)),"MGLT02609")
					_lRet:= .F.
					Exit
				EndIf        				    							                     
				(_cAliasExc)->(DBSkip())
			EndDo       
		
			//=============================================================
			//Caso nao tenha encontrado problema no cancelamento dos     
			//registros de complemento atualiza a tabela ZZD com o numero
			//de registros cancelados e o nome do usuario que realizou o 
			//cancelamento.                                              
			//=============================================================
			If _lRet
				
				DBSelectArea("ZZD")
				ZZD->(DBSetOrder(1))
				If ZZD->(DBSeek(xFilial("ZZD") + cGNumero))
					
					RecLock("ZZD",.F.)     
						
					    _nVolLeite:=  ZZD->ZZD_VOLUME - _nVolLeite	                    
						
						ZZD->ZZD_VOLUME:= _nVolLeite
						ZZD->ZZD_VLRTOT:= _nVolLeite * ZZD->ZZD_VALOR   
						
						ZZD->ZZD_NRREGE:= ZZD->ZZD_NRREGE + _nCountRec     
						ZZD->ZZD_USERAC:= _cMatUsr
						
					ZZD->(MSUnLock())     
					
				Else
					MsgStop("Problema encontrado no cancelamento do complemento de pagamento. Não foi possível atualizar a tabela ZZD,favor "+;
							"comunicar ao departamento de informática.","MGLT02610")
					_lRet:= .F.
				EndIf	 			    											
	
			 EndIf      
			      		 
			//============================================================
			//Atualizando os itens do complemento de pagamento que foram
			//cancelados.                                               
			//============================================================
			If _lRet
				//===========================================================
				//Efetua a atualizacao do status da tabela ZZG de itens do 
				//complemento de pagamento para o status cancelado.   		
				//===========================================================
				_cQuery := "UPDATE "    
				_cQuery += RetSqlName("ZZG") + " ZZG "    
				_cQuery += "SET ZZG_STATUS = '2' "
				_cQuery += "WHERE"  
				_cQuery += " D_E_L_E_T_ = ' '"
				_cQuery += " AND ZZG_FILIAL = '"       + xFilial("ZZG")  + "'"    
				_cQuery += " AND ZZG_CODIGO = '"       + ZZD->ZZD_CODIGO + "'" 
				_cQuery += " AND ZZG_FORNEC BETWEEN '" + cGProdIni  + "' AND '" + cGProdFin  + "'"          
				_cQuery += " AND ZZG_LJFORN BETWEEN '" + cGLjProdIn + "' AND '" + cGLjProdFi + "'" 
				_cQuery += " AND ZZG_LINHA BETWEEN '"  + cGLinIni   + "' AND '" + cGLinFin   + "'" 
				If TCSqlExec( _cQuery ) < 0
			 		MsgStop("Problema encontrado ao tentar cancelar os itens do complemento de pagamento. Não foram encontrados registros dos itens "+;
			 				"do complemento de pagamento na tabela ZZG, favor comunicar ao departamento de informática.","MGLT02611")
					_lRet:= .F.
			 	EndIf
			 
			EndIf
			
			If !_lRet
				//==============================================================
				//Caso encontre algum problema no cancelamento dos complemento
				//de pagamento a transacao eh desarmada.                      
				//==============================================================
				DisarmTransaction()
			EndIf
	     
		End Transaction      
	Else
		MsgStop("Não foram encontrados registros referente ao complemento de pagamento. Favor verificar os parâmetros informados para realizar o "+;
				" cancelamento e se o mix de destino não se encontra fechado, ou com o status efetivado.","MGLT02612")
		_lRet:= .F.	 
	EndIf          
	
	(_cAliasExc)->(DBCloseArea())
	    	
	//=================================================================
	//Produtores com o status efetivado ou fechado no Mix, nao podera
	//realizar a operacao.                                           
	//=================================================================
Else   	
	MsgStop("Existe(m) produtor(es) que consta(m) com o seu status no mix como efetivado ou fechado. Desta forma não será gerado o cancelamento do "+;
			"complemento de pagamento, favor alterar no mix o status dos produtores para aberto antes de realizar esta operação.","MGLT02613")
	_lRet:= .F.
EndIf	

Return _lRet       

/*
===============================================================================================================================
Programa----------: MGLT026A
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 12/01/2011
Descrição---------: Processa a alteracao do valor do complemento de pagamento gerados na inclusao. 
Parametros--------: _cCodEvent - codigo do evento  
Retorno-----------: _lRet - Lógico indicando sucesso do cancelamento
===============================================================================================================================
/*/  
Static Function MGLT026A(_cCodEvent) 

Local _nCountRec:= 0    
Local _lRet		:= .T.
Local _nNovoVlr	:= 0
Local _cMatUsr	:= FWSFAllUsers({RetCodUsr()},{"USR_FILIAL","USR_CODFUNC"})[1][3]+FWSFAllUsers({RetCodUsr()},{"USR_FILIAL","USR_CODFUNC"})[1][4]

Private _cAliasExc
Private _cAliaIncl:= GetNextAlias()
                                
//===================================================================
//Verifica se o status no mix dos produtores selecionados de acordo
//com os parametros informados pelo usuario para constatar senao   
//existir produtor efetivado ou com o status fechado no mix.       
//===================================================================
Processa( {||MGLT026Q(5,"")}/*bAction*/, "Aguarde..."/*cTitle */, "Verificando status dos produtores selecionados no Mix..."/*cMsg */,.F./*lAbort */)
_nCountRec := _nContReg   

(_cAliaIncl)->(DBCloseArea())

If _nCountRec == 0     

	_cAliasExc:= GetNextAlias()
	
	//==============================================================
	//Query para selecionar os registros do complemento de acorfdo
	//com os parametros informados pelo usuário, na inclusao      
	//==============================================================
	Processa( {||MGLT026Q(4,"",_cCodEvent)}/*bAction*/, "Aguarde..."/*cTitle */, "Selecionando registros para realizar a alteração..."/*cMsg */,.F./*lAbort */)
	_nCountRec := _nContReg      
	
	ProcRegua(_nCountRec) 
	
	If _nCountRec > 0   
	
		Begin Transaction                       
	
		DBSelectArea(_cAliasExc)
		(_cAliasExc)->(DBGoTop())
		
		While (_cAliasExc)->(!Eof())  			 
		
			IncProc()      			
			
				_nNovoVlr:= (_cAliasExc)->QTDELEITE * cGVlrRepor
			                         
				DBSelectArea("ZLF")	                         
				ZLF->(DBGoTo((_cAliasExc)->RECNOZLF))
				
				If ZLF->ZLF_EVENTO == _cCodEvent .And. cGNumero+"MGLT026" $ ZLF->ZLF_SEEKCO 
					RecLock("ZLF",.F.)  
							ZLF->ZLF_TOTAL  := _nNovoVlr
							ZLF->ZLF_VLRLTR := (_nNovoVlr/ZLF->ZLF_QTDBOM)   
					ZLF->(MSUnLock())	
				Else 
					MsgStop("Problema encontrado no cancelamento do complemento de pagamento. Favor comunicar ao departamento de informática de tal "+;
							"problema encontrado, o erro ocorreu no R_E_C_N_O_ : " + AllTrim(Str((_cAliasExc)->RECNOZLF)),"MGLT02614")
					_lRet:= .F.
					Exit	 
				EndIf     				
		                         
			DBSelectArea(_cAliasExc)
			(_cAliasExc)->(DBSkip())
		EndDo       
		
		//=============================================================
		//Caso nao tenha encontrado problema no cancelamento dos     
		//registros de complemento atualiza a tabela ZZD com o numero
		//de registros cancelados e o nome do usuario que realizou o 
		//cancelamento.                                              
		//=============================================================
		If _lRet
			
			DBSelectArea("ZZD")
			ZZD->(DBSetOrder(1))
			If ZZD->(DBSeek(xFilial("ZZD") + cGNumero))
				RecLock("ZZD",.F.)     
					ZZD->ZZD_VALOR := cGVlrRepor
					ZZD->ZZD_VLRTOT:= cGVlrRepor * ZZD->ZZD_VOLUME    
					ZZD->ZZD_USERAC:= _cMatUsr
				ZZD->(MSUnLock())     
			Else
				MsgStop("Problema encontrado na alteração do complemento de pagamento. Não foi possível atualizar a tabela ZZD,favor comunicar ao "+;
						"departamento de informática.","MGLT02615")
				_lRet:= .F.
			EndIf	 			    											
		EndIf
		
		If _lRet
			_cQuery := "UPDATE "    
			_cQuery += RetSqlName("ZZG") + " ZZG "    
			_cQuery += "SET ZZG_VALOR = " + Str(cGVlrRepor,6,4) + ",ZZG_VLRTOT = ZZG_VOLUME * " + Str(cGVlrRepor,6,4) + " "
			_cQuery += "WHERE"  
			_cQuery += " D_E_L_E_T_ = ' '"
			_cQuery += " AND ZZG_FILIAL = '"       + xFilial("ZZG")  + "'"    
			_cQuery += " AND ZZG_CODIGO = '"       + ZZD->ZZD_CODIGO + "'" 
			_cQuery += " AND ZZG_STATUS = '1'"          

			If TCSqlExec( _cQuery ) < 0
				MsgStop("Problema encontrado ao tentar atualizar os itens do complemento de pagamento. Não foram encontrados registros dos itens do "+;
						"complemento de pagamento na tabela ZZG, favor comunicar ao departamento de informática.","MGLT02616")
			    _lRet:= .F.
		 	EndIf
		EndIf
		
		If !_lRet
		
			//==============================================================
			//Caso encontre algum problema no cancelamento dos complemento
			//de pagamento a transacao eh desarmada.                      
			//==============================================================
			DisarmTransaction()     
		
		EndIf
	     
	    End Transaction      
	     
	Else
		MsgStop("Não foram encontrados registros referente ao complemento de pagamento. Favor comunicar ao departamento de informática de tal problema encontrado.","MGLT02617")
		_lRet:= .F.	 
	EndIf          
	
	(_cAliasExc)->(DBCloseArea())
	
//=================================================================
//Produtores com o status efetivado ou fechado no Mix, nao podera
//realizar a operacao.                                           
//=================================================================
Else   	
	MsgStop("Existe(m) produtor(es) que consta(m) com o seu status no mix como efetivado ou fechado. Desta forma não será gerada a alteração do "+;
			"complemento de pagamento, favor alterar no mix o status dos produtores para aberto antes de realizar esta operação.","MGLT02618")
	_lRet:= .F.	 
EndIf	

Return _lRet
