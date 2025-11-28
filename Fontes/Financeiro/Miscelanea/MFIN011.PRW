/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |22/04/2025| Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
Lucas Borges  |09/05/2025| Chamado 50617. Corrigir chamada estática no nome das tabelas do sistema
Alex Wallauer |06/05/2025| Chamado 50525. Ajuste para remoção de diretório Local C:\SMARTCLIENT\.
===============================================================================================================================
*/

#Include	"Protheus.Ch"
#Include	"FWMVCDef.Ch"

/*
===============================================================================================================================
Programa----------: MFIN011
Autor-------------: Josué Danich Prestes
Data da Criacao---: 25/02/2016
Descrição---------: Rotina de Análise de pagamentos previsos - Chamado 14623
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MFIN011()

Local oproc

//===========================================================================
//| Define formato de data para exibição nas telas da rotina                |
//===========================================================================
SET DATE FORMAT TO "DD/MM/YYYY"

//Grava Log de execução da rotina
U_ITLOGACS( "MFIN011" )

FWMsgRun( ,{|oproc| MFIN011INI(oproc) } , "Processando..." , "Iniciando o processamento..." )
	
Return

/*
===============================================================================================================================
Programa----------: MFIN011INI
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/03/2014
Descrição---------: Rotina de montagem da tela de processamento
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MFIN011INI(oproc2)

Local _aParAux	:= {}
Local _aParRet	:= {}
Local _aCpos		:= MFIN011CPS()
Local _aFields		:= {}
Local _nreg		:= 0
Local _aDados		:= {}
Local _apesqui	:= {}
Local _nHandle	:= 0
Local _nI			:= 0
Local _nlayout	:= 0 //Layout em uso - 1 Pao de acucar, 2 Atacadao, 3 Wall Mart
Local _carq		:= ""
Local _llibof		:= .F.
Local oproc
Local nI		:= 0
Default oproc2 := nil

Private oMarkBRW  := Nil
Private cAliasAux := GetNextAlias()
Private _nTotReg  := 0
Private cDtIni    := ""
Private _cDirLocal:=GetTempPath()
 
aAdd( _aParAux , { 1 , "Selecione arquivo:"		, Space(150)	, "@!"		, ""	, "DIR"		, "" , 100 , .F. } ) 	//| 01 |

For nI := 1 To Len( _aParAux )
	aAdd( _aParRet , _aParAux[nI][03] )
Next nI

If !ParamBox( _aParAux , "Análise de pagamentos previstos" , @_aParRet )
	U_ITMsg( "Operação cancelada pelo usuário!" , "Atenção!",,1 )
	Return
EndIf

ProcRegua(0)
IncProc( "Abrindo arquivo..." )

MV_PAR01:=AllTrim(MV_PAR01)

//Se For arquivo excel vai converte primeiro para csv para poder trabalhar
If Upper(right(AllTrim(MV_PAR01),3)) == "XLS" .Or. Upper(right(AllTrim(MV_PAR01),4)) == "XLSX" 

     If ValType(oproc2) = "O"
      	oproc2:cCaption := ("Detectado arquivo XLS convertendo para CSV...")
   		ProcessMessages()
    EndIf
	
	//detecta se é excel ou libreoffice e cria script de conversão
	ferase(_cDirLocal+"converzz.vbs")
	ferase(_cDirLocal+"csvtemp.csv")
	ferase(_cDirLocal+"testa.bat")
	ferase(_cDirLocal+"resp.txt")
	
	_nHandle := FCreate(_cDirLocal+"testa.bat")
	FWrite(_nHandle, 'reg query "HKEY_CLASSES_ROOT\Excel.Application\CurVer" > '+_cDirLocal+'resp.txt' + CHR(13))
	FClose(_nHandle)	
	
	shellexecute("Open",_cDirLocal+"testa.bat","","",0)
	
	//tempo de espera para garantir que arquivo foi finalizado
	Sleep(1000)
		
	FT_FUSE(_cDirLocal+"resp.txt")
	
	FT_FSKIP()
		
	_cDados := FT_FREADLN()
	
	If _cDados == "HKEY_CLASSES_ROOT\Excel.Application\CurVer"  //Tem Excel
		
		If ValType(oproc2) = "O"
      	  oproc2:cCaption := ("Usando Excel para converter para CSV...")
   		  ProcessMessages()
        EndIf
		
		_nHandle := FCreate(_cDirLocal+"converzz.vbs")
		FWrite(_nHandle, "Dim oExcel" + CHR(13))
		FWrite(_nHandle, 'Set oExcel = CreateObject("Excel.Application")'+ CHR(13))
		FWrite(_nHandle, "Dim oBook"+ CHR(13))
		FWrite(_nHandle, "Set oBook = oExcel.Workbooks.Open(Wscript.Arguments.Item(0))"+ CHR(13))
		FWrite(_nHandle, 'oBook.Sheets(1).Range("A1:A99999").NumberFormat = "################"'+ CHR(13))
		FWrite(_nHandle, "oBook.SaveAs WScript.Arguments.Item(1), 6"+ CHR(13))
		FWrite(_nHandle, "oBook.Close False"+ CHR(13))
		FWrite(_nHandle, "oExcel.Quit"+ CHR(13))
		FClose(_nHandle)

		ShellExecute("open", _cDirLocal+"converzz.vbs", MV_PAR01+" "+_cDirLocal+"csvtemp.csv", "", 0)
	Else
		U_ITMsg("Falha ao converter o arquivo excel para .csv","Erro","Instale o Excel. pois não foi encontrado.",1)
		ferase(_cDirLocal+"testa.bat")
        ferase(_cDirLocal+"resp.txt")
		Return
	EndIf
	    
	//tempo de espera para garantir que arquivo foi finalizado
	Sleep(5000)
	
	If FT_FUSE(_cDirLocal+"csvtemp.csv") == -1
		U_ITMsg("Falha ao converter o arquivo excel","Erro",,1)
		Return
	EndIf 
			
	//Detecta layout de client
	FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
	_cDados := FT_FREADLN()
	
	If AllTrim(_cDados) == "ORIGEM,CGC_CPF,RAZAO_SOCIAL,FILIAL,COD_PORTADOR,PARCELA,NR_DOCTO,DT_VECTO,DT_RECEBE,VALOR_EFETIVO,DESCRM,DESCCOPAG,VLR_ABATIMENTO,VALOR_PAGAR"
		_nlayout := 2 //Atacadao
	EndIf
	
	If _cDados == "Remetente,Wal-Mart Brasil,,,,,,,,,,,"
	
		FT_FSKIP()
		FT_FSKIP()
		FT_FSKIP()
		FT_FSKIP()
		FT_FSKIP()
		FT_FSKIP()
		FT_FSKIP()
		FT_FSKIP()
		FT_FSKIP()
		_cDados := FT_FREADLN()
		
		If _cDados == "Empresa,Nota Fiscal,Loja,Tipo Doc.,Nro.Doc.SAP,Valor NF,Vencimento,Situação,Data Compensação,CPF / CNPJ Fornecedor ,,,"
			_nlayout := 3 //Wall Mart
		EndIf
		
	EndIf
	
	If _cDados == "Empresa,Descrição da Empresa,Divisão,Descrição da Divisão,Exercício,Nome,Nº ID fiscal 1,Texto de cabeçalho de documento,Documento da Fatura,Origem da Fatura,Tipo de Documento de Compensação,Referência da fatura,Data do Documento,Data do Lançamento,Data de Vencimento,Data de Compensação,Montante em moeda interna,Valor da Fatura,Valor Compensado,Status,Boleto Vinculado,Denominação Forma Pagamento,Chave para o bloqueio de Pagamento,Denominação Bloqueio Pagamento,Nº documento de estorno,Documento de Compensação,Nº atribuição,Tipo de Documento,Nota Fiscal ou Documento de Referencia,Texto do item"
		_nlayout := 4 //Carrefour
	EndIf
	
	//Fecha arquivo e prepara parâmetro com arquivo convertido
	FT_FUSE()
	_carq := _cDirLocal+"csvtemp.csv"
	
ElseIf (Upper(right(AllTrim(MV_PAR01),3)) == "TXT" .Or. Upper(right(AllTrim(MV_PAR01),3)) == "SCP")
	_nlayout := 1 //Pao de Acucar, unico layout em arquivo texto até agora
	_carq := MV_PAR01
ElseIf (Upper(right(AllTrim(MV_PAR01),3))) == "CSV" 
	If FT_FUSE(MV_PAR01) == -1
		U_ITMsg("Falha ao abrir o arquivo","Erro",,1)
		Return
	EndIf 
	          
	_carq := MV_PAR01
			
	//Detecta layout de client
	FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
	_cDados := FT_FREADLN()
	
	If SubStr(StrTran(_cDados,',',';'),1,50) == "CnpjFornecedor;NumeroNota;TipoDocumento;Loja;CnpjL"
		_nlayout := 5 //Cencosud
	EndIf
	If SubStr(StrTran(_cdados,'"',''),1,49) == "CNPJ Pagador,Fornecedor,(R$) Valor do Documento,N"
		_nlayout := 6 //Assai
	EndIf
	If SubStr(StrTran(_cdados,'"',''),1,49) == "Nro Doc,Loja,Nro Pedido,Nro Forn,Nro Filial,Tipo,"
		_nlayout := 7 //Makro
	EndIf    
	If SubStr(Upper(_cdados),1,17) == "TITULOS A RECEBER"
	   _nlayout := 8 // IRMAOS MUFFATO & CIA LTDA.
	EndIf
	
ElseIf (Upper(right(AllTrim(MV_PAR01),3)) == "HTM" .Or. Upper(right(AllTrim(MV_PAR01),3)) == "HTML")  
	If FT_FUSE(MV_PAR01) == -1
	   U_ITMsg("Falha ao abrir o arquivo","Erro",,1)
	   Return
	EndIf 
	          
	_carq := MV_PAR01
			
	//Detecta layout de client
	FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
	_cDados := FT_FREADLN()
    
    If "ATACADAO S.A" $ _cDados
       _nlayout := 9  //  Atacadão S/A
    EndIf
	
EndIf


//Escolhido Layout continua leitura
If _nlayout > 0

	If FT_FUSE(_carq) == -1
		U_ITMsg("Não foi possível abrir o arquivo informado.",;
		"Arquivo inválido","Favor verificar se o arquivo informado esta correto.",1)
		Return
	EndIf
	
	FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
	
	_nReg:= FT_FLASTREC()

	ProcRegua(_nReg)
	
	FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
	
	If _nReg == 0 //O arquivo informado nao possui nenhuma linha de dados
		U_ITMsg(	"O arquivo informado para relizar a importação não possui dados.",;
		"Arquivo inválido","Favor verificar se o arquivo informado esta correto.",1)
		Return
	EndIf

	If _nlayout == 1
		_aDados := MFIN011L1(_nreg,oproc2) //Faz leitura dos dados no layout do Pao de Acucar
	ElseIf _nlayout == 2
		_aDados := MFIN011L2(_nreg,_llibof,oproc2) //Faz leitura dos dados no layout do Atacadao
	ElseIf _nlayout == 3
		_aDados := MFIN011L3(_nreg,oproc2) //Faz leitura dos dados no layout do Wall Mart
	ElseIf _nlayout == 4
		_aDados := MFIN011L4(_nreg,oproc2) //Faz leitura dos dados no layout do Carrefour
	ElseIf _nlayout == 5
		_aDados := MFIN011L5(_nreg,oproc2) //Faz leitura dos dados no layout do Cencosud
	ElseIf _nlayout == 6
		_aDados := MFIN011L6(_nreg,oproc2) //Faz leitura dos dados no layout do Assai
	ElseIf _nlayout == 7
		_aDados := MFIN011L7(_nreg,oproc2) //Faz leitura dos dados no layout do Makro
	ElseIf _nlayout == 8
		_aDados := MFIN011L8(_nreg,oproc2) //Faz leitura dos dados no layout dos IRMAOS MUFFATO & CIA LTDA.
	ElseIf _nlayout == 9
		_aDados := MFIN011L9(_nreg,oproc2) //Faz leitura dos dados no layout do Atacadão S/A
	EndIf

	If Len(_aDados) <= 0
		U_ITMsg(  "Não foram encontrados registros válidos no arquivo!" ,"Atenção!",,1 )
		Return
	EndIf

Else
	U_ITMsg("O arquivo informado para relizar a importação não tem layout conhecido.",;
  		    "Arquivo inválido","Favor verificar se o arquivo informado esta correto.",1)
		Return
EndIf


//=========================================
//ordena titulos no browse
//=========================================
_aDados := aSort( _aDados,,, { |x,y| x[06]+x[03]+x[04]+x[01]+x[02] < y[06]+y[03]+y[04]+y[01]+y[02] } )

ProcRegua(Len(_aDados))

//================================================================================
// Verifica se ja existe um arquivo com mesmo nome, se sim deleta.
//================================================================================
If Select(cAliasAux) > 0
	(cAliasAux)->( DBCloseArea() )
EndIf

//================================================================================
// Permite o uso do arquivo criado dentro do protheus.
//================================================================================
_otemp := FWTemporaryTable():New( cAliasAux, _aCpos )

_otemp:AddIndex( "01",{"FILIAL","TITU"} )

_otemp:Create()

_nI := 0

While _nI < Len(_aDados)
	
	_nI++
	IncProc( "Analisando... ["+ StrZero( _nI , 6 ) +"] de ["+ StrZero( _nI , 6 ) +"]" )
	
	//=========================================================================================
	//localiza título
	// se não achar e For parcela 001 procura com parcela em branco
	// se não achar não mostra na tela
	//==========================================================================================
	
	DBSelectArea("SE1")
	SE1->(DBSetOrder(2))
	
	If .not. SE1->(DBSeek(_aDados[_nI][06]+_aDados[_nI][03]+_aDados[_nI][04]+"1  "+_aDados[_nI][01]+_aDados[_nI][02]))
		If .not. (_aDados[_nI][02] == "001" .Or. _aDados[_nI][02] == "01")
			_nI++
			Loop
		ElseIf .not. 	SE1->(DBSeek(_aDados[_nI][06]+_aDados[_nI][03]+_aDados[_nI][04]+"1  "+_aDados[_nI][01]))
			_nI++
			Loop
		EndIf
	EndIf
	
	(cAliasAux)->( RecLock( cAliasAux , .T. ) )

		(cAliasAux)->FILIAL		:= _aDados[_nI][06]
		(cAliasAux)->CLIENTE		:= _aDados[_nI][03]
		(cAliasAux)->LOJA			:= _aDados[_nI][04]
		(cAliasAux)->NOME 		:= Posicione("SA1",1,xFilial("SA1")+_aDados[_nI][03]+_aDados[_nI][04],"A1_NOME")
		(cAliasAux)->REDE			:= Capital( AllTrim( Posicione("ACY",1, xFilial("ACY")+Posicione("SA1",1,xFilial("SA1")+_aDados[_nI][03]+_aDados[_nI][04],"A1_GRPVEN"),"ACY_DESCRI")))
		(cAliasAux)->CGC			:= MFIN011CGC( _aDados[_nI][07] )
		(cAliasAux)->TITU			:= _aDados[_nI][01]
		(cAliasAux)->PARCELA		:= _aDados[_nI][02]
		(cAliasAux)->CONDI		:= Posicione("SA1",1,xFilial("SA1")+_aDados[_nI][03]+_aDados[_nI][04],"A1_COND")
		(cAliasAux)->DCONDI		:= Posicione("SE4",1,xFilial("SE4")+(cAliasAux)->CONDI,"E4_DESCRI")
		(cAliasAux)->VALOR		:= SE1->E1_VALOR
		(cAliasAux)->VENCTO		:= SE1->E1_VENCTO
		(cAliasAux)->VENCREA		:= SE1->E1_VENCREA
		(cAliasAux)->VENCNVO		:= _aDados[_nI][05]
		(cAliasAux)->REGSE1		:= SE1->( Recno() )

	(cAliasAux)->( MSUnLock() )

EndDo

aAdd( _aFields , { "Filial"	 		   	, {|| (cAliasAux)->FILIAL + " - " +  AllTrim(FWFilialName(cEmpAnt,(cAliasAux)->FILIAL,1))}  	, "C" , "@!" , 0 , 12, 0 } )
aAdd( _aFields , { "Cliente"			, {|| (cAliasAux)->CLIENTE + " - " + (cAliasAux)->LOJA }  											, "C" , "@!" , 0 , 08		, 0 } )
aAdd( _aFields , { "Nome"				, {|| AllTrim((cAliasAux)->NOME) + " - " + AllTrim((cAliasAux)->REDE)}							, "C" , "@!" , 0 , 30		, 0 } )
aAdd( _aFields , { "CNPJ"				, {|| (cAliasAux)->CGC }	  											, "C" , "@!" , 0 , 12		, 0 } )
aAdd( _aFields , { "Titulo"				, {|| (cAliasAux)->TITU + " - " + (cAliasAux)->PARCELA }		, "C" , "@!" , 0 , 9			, 0 } )
aAdd( _aFields , { "Condição"			, {|| (cAliasAux)->CONDI + " - " + (cAliasAux)->DCONDI }		, "C" , "@!" , 0 , 9			, 0 } )
aAdd( _aFields , { "Valor"				, {|| (cAliasAux)->VALOR }											, "N" , "@E 999,999,999.99" , 0 , 7, 2 } )
aAdd( _aFields , { "Venc. Real"			, {|| DToC((cAliasAux)->VENCREA) }									, "C" , "@!" , 0 , 5			, 0 } )
aAdd( _aFields , { "Venc. Arq."			, {|| DToC((cAliasAux)->VENCNVO)}									, "C" , "@!" , 0 , 5			, 0 } )
aAdd( _aFields , { "Venc. Novo"			, {|| MFIN011AV((cAliasAux)->VENCNVO,(cAliasAux)->CONDI)}	, "C" , "@!" , 0 , 5			, 0 } )

oMarkBRW := FWMarkBrowse():New()		   												// Inicializa o Browse
oMarkBRW:SetAlias( cAliasAux )			   												// Define Alias que será a Base do Browse
oMarkBRW:SetDescription( "Títulos para ajustar" )									// Define o titulo do browse de marcacao
oMarkBRW:SetFieldMark( "MARCA" )														// Define o campo que sera utilizado para a marcação
oMarkBRW:SetMenuDef( 'MFIN011' )														// Força a utilização do menu da rotina atual
oMarkBRW:SetAllMark( {|| oMarkBRW:AllMark() } )											// Ação do Clique no Header da Coluna de Marcação
oMarkBRW:SetFields( _aFields )													 		// Campos para exibição

_apesqui := {}
aAdd(_apesqui,{"Titulo",{{"Filial","C",2,0,"Filial",,}, {"Titulo","C",9,0,"Titulo",,}},1})

oMarkBRW:SetSeek(.T., _apesqui)

oMarkBRW:AddButton( "Confirmar" , {|| FWMsgRun( ,{|oproc| U_MFIN011B(oproc) } , "Ajustando títulos..." , "Aguarde!" ) } ,, 4 )

oMarkBRW:DisableConfig()
oMarkBRW:Activate()																		// Ativacao da classe

(cAliasAux)->( DBCloseArea() )

ferase(_cDirLocal+"converzz.vbs")
ferase(_cDirLocal+"csvtemp.csv")
ferase(_cDirLocal+"testa.bat")
ferase(_cDirLocal+"resp.txt")

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/03/2014
Descrição---------: Rotina de construção do menu
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MenuDef()

Local aRotina	:= {}

ADD OPTION aRotina Title 'Consultar'	Action 'U_MFIN011R( (cAliasAux)->REGSE1 )'															  		OPERATION 2 ACCESS 0

Return( aRotina )

/*
===============================================================================================================================
Programa----------: MFIN011CNS
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/03/2014
Descrição---------: Rotina de consulta do cadastro completo do Cliente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function MFIN011R( nRegSe1 )

Private cCadastro := "Título a receber"

DBSelectArea("SE1")
SE1->( DBGoTo(nRegSE1) )
AxVisual( "SE1" , nRegSE1 , 2 )

Return

/*
===============================================================================================================================
Programa----------: MFIN011CPS
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/03/2014
Descrição---------: Define a criação de campos para exibição da análise
Parametros--------: Nenhum
Retorno-----------: aRet - Campos que serão criados e exibidos na tela
===============================================================================================================================
*/
Static Function MFIN011CPS( _nTotReg )

Local _aCpos := {}

aAdd( _aCpos , { "MARCA"			, "C" , 1								, 0 } )
aAdd( _aCpos , { "FILIAL"		, "C" , TamSX3("A1_FILIAL")[01]		, 0 } )
aAdd( _aCpos , { "CLIENTE"		, "C" , TamSX3("A1_COD")[01]		, 0 } )
aAdd( _aCpos , { "LOJA"			, "C" , TamSX3("A1_LOJA")[01]		, 0 } )
aAdd( _aCpos , { "NOME"			, "C" , TamSX3("A1_NOME")[01]		, 0 } )
aAdd( _aCpos , { "REDE"			, "C" , TamSX3("ACY_DESCRI")[01]	, 0 } )
aAdd( _aCpos , { "CGC"			, "C" , 20							, 0 } )
aAdd( _aCpos , { "TITU"		, "C" , 9								, 0 } )
aAdd( _aCpos , { "PARCELA"		, "C" , 3								, 0 } )
aAdd( _aCpos , { "CONDI"			, "C" , 5 								, 0 } )
aAdd( _aCpos , { "DCONDI"		, "C" , 20								, 0 } )
aAdd( _aCpos , { "VALOR"			, "N" , 18								, 2 } )
aAdd( _aCpos , { "VENCTO"		, "D" , 8								, 0 } )
aAdd( _aCpos , { "VENCREA"		, "D" , 8								, 0 } )
aAdd( _aCpos , { "VENCNVO"		, "D" , 8								, 0 } )
aAdd( _aCpos , { "REGSE1"		, "N" , 18								, 0 } )

Return( _aCpos )

/*
===============================================================================================================================
Programa----------: MFIN011B
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/03/2014
Descrição---------: Processa o o ajuste de vencimentos dos titulos marcados
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: aRet - Campos que serão criados e exibidos na tela
===============================================================================================================================
*/
User Function MFIN011B(oproc)

Local _nRegAtu	:= 0
Local _nTotReg	:= 0
Local _nRegSel	:= 0
Local _cNumLote	:= ""

ProcRegua(_nTotReg)
(cAliasAux)->( DBGoTop() )

Begin Transaction

_cNumLote := U_ITInLote( "Z00" , "001" )

//===========================================================================
//| Verifica a quantidade de Registros no Browse                            |
//===========================================================================
oMarkBRW:GoBottom()
_nTotReg := oMarkBRW:At()
oMarkBRW:GoTop()

While _nRegAtu < _nTotReg
	
	_nRegAtu++
	
	If ValType(oproc) = "O"
		oproc:cCaption := ("Processando... ["+ StrZero(_nRegAtu,6) +"] de ["+ StrZero(_nTotReg,6) +"]")
		ProcessMessages()
    EndIf
	
	oMarkBRW:GoTo( _nRegAtu , .F. )
	
	If oMarkBRW:IsMark()
	
		_nRegSel++
		
		//atualiza campos do SE1
		
		DBSelectArea("SE1")
		SE1->( DBSetOrder(2) )
		
		If  SE1->(DBSeek((cAliasAux)->FILIAL+(cAliasAux)->CLIENTE+(cAliasAux)->LOJA+"1  "+(cAliasAux)->TITU	+AllTrim((cAliasAux)->PARCELA)))	
	
			SE1->( RecLock( "SE1" , .F. ) )
	 
			SE1->E1_VENCREA	:= ctod(MFIN011AV((cAliasAux)->VENCNVO,(cAliasAux)->CONDI))
			SE1->E1_I_VCPOR	:= ctod(MFIN011AV((cAliasAux)->VENCNVO,(cAliasAux)->CONDI))
			SE1->E1_I_VCFLU	:= ctod(MFIN011AV((cAliasAux)->VENCNVO,(cAliasAux)->CONDI))
			SE1->( MSUnLock() )
			
			(cAliasAux)->( RecLock( cAliasAux , .F. ) )
			(cAliasAux)->VENCREA  := ctod(MFIN011AV((cAliasAux)->VENCNVO,(cAliasAux)->CONDI))
			(cAliasAux)->( MSUnLock() )
			oMarkBRW:MarkRec()
			oMarkBRW:Refresh()
			
			//===========================================================================
			//| Grava o Item processado no Lote                                         |
			//===========================================================================
			U_ITGrLote( "Z03" , _cNumLote , { { SE1->E1_FILIAL + SE1->E1_NUM + SE1->E1_PARCELA , SToD( cDtIni ) , Date() , "1" } } , "1" )
	
			
			
		ElseIf ((cAliasAux)->PARCELA = '001' .Or. (cAliasAux)->PARCELA = '01') .And. SE1->(DBSeek((cAliasAux)->FILIAL+(cAliasAux)->CLIENTE+(cAliasAux)->LOJA+"1  "+(cAliasAux)->TITU ))
		
			SE1->( RecLock( "SE1" , .F. ) )
			SE1->E1_VENCREA	:= ctod(MFIN011AV((cAliasAux)->VENCNVO,(cAliasAux)->CONDI))
			SE1->E1_I_VCPOR	:= ctod(MFIN011AV((cAliasAux)->VENCNVO,(cAliasAux)->CONDI))
			SE1->E1_I_VCFLU	:= ctod(MFIN011AV((cAliasAux)->VENCNVO,(cAliasAux)->CONDI))
			SE1->( MSUnLock() )
			
			(cAliasAux)->( RecLock( cAliasAux , .F. ) )
			(cAliasAux)->VENCREA		:= ctod(MFIN011AV((cAliasAux)->VENCNVO,(cAliasAux)->CONDI))
			(cAliasAux)->( MSUnLock() )
			oMarkBRW:MarkRec()
			oMarkBRW:Refresh()
		
		
			//===========================================================================
			//| Grava o Item processado no Lote                                         |
			//===========================================================================
			U_ITGrLote( "Z03" , _cNumLote , { { SE1->E1_FILIAL + SE1->E1_NUM + SE1->E1_PARCELA , SToD( cDtIni ) , Date() , "1" } } , "1" )
		
		Else
		
			U_ITGrLote( "Z03" , _cNumLote , { { SE1->E1_FILIAL + SE1->E1_NUM + SE1->E1_PARCELA , SToD( cDtIni ) , Date() , "1" } } , "2" )
			
		EndIf			
		
	EndIf
	
	(cAliasAux)->( DBSkip() )
	
EndDo

(cAliasAux)->( DBGoTop() )

U_ITFnLote( "Z00" , _cNumLote )

End Transaction

//===========================================================================
//| Verifica o Status geral do processamento.                               |
//===========================================================================
If _nRegSel > 0
	U_ITMsg( "Registros processados com sucesso!" , "Concluído!" ,,2)
Else

	//===========================================================================
	//| Exclui o Lote que não teve registros processados.                       |
	//===========================================================================
	DBSelectArea("Z00")
	If Z00->( DBSeek( xFilial("Z00") + _cNumLote ) )
		
		Z00->( RecLock( "Z00" , .F. ) )
		Z00->( DBDelete() )
		Z00->( MSUnLock() )
		
	EndIf
	
	U_ITMsg( "O processamento foi concluído porém nenhum registro foi selecionado para o atualização!" , "Concluído!",,3 )

EndIf

oMarkBRW:Refresh()
oMarkBRW:GoTop()

Return

/*
===============================================================================================================================
Programa----------: MFIN011CGC
Autor-------------: Josué Danich Prestes
Data da Criacao---: 02/06/2014
Descrição---------: Formatação da Máscara para CPF/CNPJ
Parametros--------: _cCGCAux - cnpj sem máscara
Retorno-----------: _cRet - cnpj com máscara
===============================================================================================================================
*/
Static Function MFIN011CGC( _cCGCAux )

Local _cRet	:= ""
Local _cAux	:= AllTrim( _cCGCAux )

If Len( _cAux	 ) > 11
	_cAux	 := PadL( _cAux	 , 14 , "0" )
	_cRet := Transform( _cAux	 , "@R! NN.NNN.NNN/NNNN-99" )
Else
	_cAux	 := PadL( _cAux	 , 11 , "0" )
	_cRet := Transform( _cAux	 , "@R 999.999.999-99" )
EndIf

Return( _cRet )

/*
===============================================================================================================================
Programa----------: MFIN011AV
Autor-------------: Josué Danich Prestes
Data da Criacao---: 02/06/2014
Descrição---------: Ajusta data de acordo com condição de pagamento para dia da semana
Parametros--------: _dvenc - data de vencimento do arquivo
					  _ccond - condição de pagamento
Retorno-----------: _dret - data de vencimento ajustada
===============================================================================================================================
*/

Static Function MFIN011AV( _dvenc, _ccond )

Local _ctipo 	:= Posicione("SE4",1,xFilial("SE4")+_ccond,"E4_TIPO")
Local _cdet	:= Posicione("SE4",1,xFilial("SE4")+_ccond,"E4_COND")
Local _adias	:= {}
Local _nI 		:= 0
Local _lsai	:= .F.

If _ctipo == "4" .Or. _ctipo == "6" //tipos de condição de pagamento que tem dia determinado da semana

	_adias := StrTokArr(_cdet,",")
	
	While !( dow(_dvenc) == Val(_adias[3]) )
		_dvenc++
	EndDo
	
	_dvenc := datavalida(_dvenc)

ElseIf _ctipo == "3"  //tipo de condição que determina dias fixos do mes para pagamento

	_adias := StrTokArr(_cdet,",")
	
	_lsai := .F.
	
	While Len(_adias) > 2 .And. !_lsai
	
		_nI := 3 
		
		While _nI <= Len(_adias)
			If StrZero(day(_dvenc),2) == StrZero(Val(_adias[_nI]),2)
				_lsai := .T.
				_nI := Len(_adias) + 1
			Else
				_nI++
			EndIf
		EndDo
		
		If !_lsai
			_dvenc++
		Else
			_dvenc := datavalida(_dvenc)
		EndIf
		
	EndDo			 

Else

	_dvenc := datavalida(_dvenc)

EndIf

Return DToC(_dvenc)

/*
===============================================================================================================================
Programa----------: MFIN011L1
Autor-------------: Josué Danich Prestes
Data da Criacao---: 09/03/2016
Descrição---------: Faz a leitura de dados no layout do Pao de Acucar
Parametros--------: _nreg - número de linhas do arquivo
					oproc2 - objeto da barra de processamento
Retorno-----------: _aDados - array com dados carregados do arquivo
===============================================================================================================================
*/

Static Function MFIN011L1(_nreg,oproc2)

Local	_nCont 	:= 0
Local	_lheader 	:= .F.	
Local _cdados		:= ""
Local _ddtcred	:= ddatabase
Local _aDados 	:= {}
Local _aSM0 		:= FWLoadSM0()  //carrega array com dados de filiais
Default oproc2 := nil

While !FT_FEOF()  //FACA ENQUANTO NAO For FIM DE ARQUIVO
	
	_nCont++
	
	If ValType(oproc2) = "O"

      	  oproc2:cCaption := ("Detectado arquivo Pao de Acucar, Lendo linha " + StrZero(_nCont,5) + " de " + StrZero(_nreg,5) + ".")
   		  ProcessMessages()
 
    EndIf
			
	_cDados := FT_FREADLN()
	
	//Se não estiver dentro de registro detalhe testa se a linha é header
	If .not. _lheader
	
		If SubStr(_cDados,1,2) == "01" .And. SubStr(_cDados,9,1) == "0"
		
			_lheader := .T.
			_ddtcred := SToD(SubStr(_cdados,217,8))
			
		EndIf
		
	//Se está dentro do registro de detalhe análise e carrega os dados
	Else
	
		If SubStr(_cDados,1,2) = "15"  // Registro detalhe de nota de crédito
		
			aAdd(_aDados, {SubStr(_cdados,3,9),;  																	//01 - num titulo
							 SubStr(_cdados,12,3),;																	//02 - parcela
							 Posicione("SA1",3,xFilial("SA1")+ AllTrim(SubStr(_cdados,254,14)),"A1_COD"),;	//03 - codigo do cliente
							 Posicione("SA1",3,xFilial("SA1")+ AllTrim(SubStr(_cdados,254,14)),"A1_LOJA"),;	//04 - loja do cliente
							 _ddtcred,;																				//05 - data de pagamento prevista
							 _aSm0[aScan( _aSm0, { |x| x[18] = SubStr(_cdados,213,14)})][2],;					//06 - filial Italac
							 AllTrim(SubStr(_cdados,254,14))})														//07 - CNPJ cliente
								                     
		Else
		
			If SubStr(_cdados,1,2) == "90" //Trailer do trecho de detalhes
			
				_lheader := .F.
				
			EndIf			
		
		EndIf	
	
	EndIf

	FT_FSKIP()
	
EndDo
	
Return _aDados


/*
===============================================================================================================================
Programa----------: MFIN011L2
Autor-------------: Josué Danich Prestes
Data da Criacao---: 09/03/2016
Descrição---------: Faz a leitura de dados no layout do Atacadao
Parametros--------: _nreg - número de linhas do arquivo
					  _llibof - se foi convertido pelo libreoffice
					oproc2 - objeto da barra de processamento					  
Retorno-----------: _aDados - array com dados carregados do arquivo
===============================================================================================================================
*/
Static Function MFIN011L2(_nreg,_llibof,oproc2)

Local	_nCont 	:= 0
Local _cdados		:= ""
Local _alinha		:= {}
Local _aDados 	:= {}
Local _cQuery		:= ""
Default oproc2 := nil

FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
FT_FSKIP()
FT_FSKIP()

While !FT_FEOF()  //FACA ENQUANTO NAO For FIM DE ARQUIVO
	
	_nCont++ 
	
	If ValType(oproc2) = "O"

      	  oproc2:cCaption := ("Detectado arquivo Atacadao, Lendo linha " + StrZero(_nCont,5) + " de " + StrZero(_nreg,5) + ".")
   		  ProcessMessages()
 
    EndIf
			
	_cDados := FT_FREADLN()
	_alinha := StrTokArr(_cDados,",")
	
	//Verifica se é final de arquivo
	If AllTrim(_cdados) == ',,,,,,,,,,,,' .And. _ncont > 5
	
		Exit
	
	EndIf 	
	
	//Verifica se é linha válida
	If Len(_alinha) < 13  
	
		FT_FSKIP()
		Loop
		
	EndIf
			
	
	//identifica filial do título
	_cQuery := "SELECT E1_FILIAL FROM " +retsqlname("SE1") + " SE1 WHERE D_E_L_E_T_ = ' '"
	_cQuery += " AND E1_NUM = '" + StrZero(Val(_alinha[7]),9) + "'"
	_cQuery += " AND E1_CLIENTE = '000039' AND E1_LOJA = '" + StrZero(Val(_alinha[4]),4) + "'
	
	_cQuery := ChangeQuery(_cQuery)
	MPSysOpenQuery(_cQuery,"SE1T")
	
	If SE1T->(!Eof())
  
		aAdd(_aDados, {StrZero(Val(_alinha[7]),9),;  															//01 - num titulo
					 "01",;					   																//02 - parcela
					 '000039',;																				//03 - codigo do cliente
					 StrZero(Val(_alinha[4]),4),;															//04 - loja do cliente
					 ctod(_alinha[8]),;																//05 - data de pagamento prevista
					 SE1T->E1_FILIAL,;		   																//06 - filial Italac
					 "7531533300" + 	StrZero(Val(_alinha[4]),4)})										//07 - CNPJ cliente
								                     
	EndIf
	
	SE1T->( DBCloseArea() )
	
	FT_FSKIP()
	
EndDo
	
Return _aDados

/*
===============================================================================================================================
Programa----------: MFIN011L3
Autor-------------: Josué Danich Prestes
Data da Criacao---: 09/03/2016
Descrição---------: Faz a leitura de dados no layout do Wall Mart
Parametros--------: _nreg - número de linhas do arquivo
					oproc2 - objeto da barra de processamento
Retorno-----------: _aDados - array com dados carregados do arquivo
===============================================================================================================================
*/

Static Function MFIN011L3(_nreg,oproc2)

Local	_nCont 	:= 0
Local _cdados		:= ""
Local _alinha		:= {}
Local _aDados 	:= {}
Local _aSM0 		:= FWLoadSM0()  //carrega array com dados de filiais
Default oproc2 := nil

FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
FT_FSKIP()
FT_FSKIP()

While !FT_FEOF()  //FACA ENQUANTO NAO For FIM DE ARQUIVO
	
	_nCont++ 

	If ValType(oproc2) = "O"

      	  oproc2:cCaption := ("Detectado arquivo Wall Mart, Lendo linha " + StrZero(_nCont,5) + " de " + StrZero(_nreg,5) + ".")
   		  ProcessMessages()
 
    EndIf
			
	_cDados := FT_FREADLN()
	_cDados := StrTran(_cDados,'"','') 
	_alinha := StrTokArr(_cDados,",")

	
	//Verifica se é final de arquivo
	If AllTrim(_cdados) == ',,,,,,,,,,,,' .And. _ncont > 20
	
		Exit
	
	EndIf 	
		
	//Verifica se é linha válida
	If Len(_alinha) < 9 .Or. ( _alinha[8] != 'Aberto' .And. _alinha[9] != 'Aberto' )
	
		FT_FSKIP()
		Loop
		
	EndIf	
	
	//Ajusta matriz
	If Len(_alinha) == 10
	
		_alinha[6] := AllTrim(Str(Val(_alinha[6]) + ( Val(_alinha[7]) /100 )))
		_alinha[7] := _alinha[8]
		_alinha[8] := _alinha[9]
		_alinha[9] := _alinha[10]
		
	EndIf
		
	
	//Ajusta CGC só com numeros 
	_alinha[9] := SubStr(_alinha[9],1,2) + SubStr(_alinha[9],4,3) + SubStr(_alinha[9],8,3) + SubStr(_alinha[9],12,4) + SubStr(_alinha[9],17,2)
		
	If aScan( _aSm0, { |x| x[18] = (AllTrim(_alinha[9]))}) > 0	
	
		//Identifica filial
		_cfilial :=  _aSm0[aScan( _aSm0, { |x| x[18] = (AllTrim(_alinha[9]))})][2]
		
		//Usa número do título para identificar o cliente e loja
		DBSelectArea("SE1")
		SE1->( DBSetOrder(1) )
		If SE1->( DBSeek( _cfilial + '1  ' + StrZero(Val(_alinha[2]),9) + '  NF') )
			
			aAdd(_aDados, {StrZero(Val(_alinha[2]),9),;  															//01 - num titulo
					 '01',;																							//02 - parcela
					 SE1->E1_CLIENTE,;																				//03 - codigo do cliente
					 SE1->E1_LOJA,;																					//04 - loja do cliente
					 ctod(_alinha[7]),;																				//05 - data de pagamento prevista
					 _aSm0[aScan( _aSm0, { |x| x[18] = (AllTrim(_alinha[9]))})][2],;			  				//06 - filial Italac
					 Posicione("SA1",1,xFilial("SA1") + SE1->E1_CLIENTE + SE1->E1_LOJA,"A1_CGC")})			//07 - CNPJ cliente
		
		EndIf
		
	EndIf
								                     
	FT_FSKIP()
	
EndDo
	
Return _aDados

/*
===============================================================================================================================
Programa----------: MFIN011L4
Autor-------------: Josué Danich Prestes
Data da Criacao---: 09/03/2016
Descrição---------: Faz a leitura de dados no layout do Carrefour
Parametros--------: _nreg - número de linhas do arquivo
					oproc2 - objeto da barra de processamento
Retorno-----------: _aDados - array com dados carregados do arquivo
===============================================================================================================================
*/

Static Function MFIN011L4(_nreg,oproc2)

Local	_nCont 	:= 0
Local _cdados		:= ""
Local _alinha		:= {}
Local _aDados 	:= {}
Local _aSM0 		:= FWLoadSM0()  //carrega array com dados de filiais
Default oproc2 := nil

FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
FT_FSKIP()
FT_FSKIP()

While !FT_FEOF()  //FACA ENQUANTO NAO For FIM DE ARQUIVO
	
	_nCont++ 

	If ValType(oproc2) = "O"

      	  oproc2:cCaption := ("Detectado arquivo Carrefour, Lendo linha " + StrZero(_nCont,5) + " de " + StrZero(_nreg,5) + ".")
   		  ProcessMessages()
 
    EndIf
			
	_cDados := FT_FREADLN()
	
	If _cDados == ",,,,,,,,,,,,,,,,,,,,,,,,,,,,," //Descarta linhas finais para agilizar processo
		Exit
	EndIf
	
	_cDados := StrTran(_cDados,",",";")
	_alinha := StrTokArr(_cDados,";")
	
	If Len(_alinha) < 24
			
		FT_FSKIP()
		Loop
		
	EndIf
	
	_alinha[7] := StrTran(_alinha[7],".","")
	_alinha[7] := StrTran(_alinha[7],"/","")
	_alinha[7] := StrTran(_alinha[7],"-","")
	
	_alinha[24] := StrTran(_alinha[23],"-","")
	_alinha[24] := SubStr(_alinha[23],1,Len(_alinha[23])-1)
	 		
	If aScan( _aSm0, { |x| x[18] = (AllTrim(_alinha[7]))}) > 0	
	
		//Identifica filial
		_cfilial :=  _aSm0[aScan( _aSm0, { |x| x[18] = (AllTrim(_alinha[7]))})][2]
		
		//Usa número do título para identificar o cliente e loja
		DBSelectArea("SE1")
		SE1->( DBSetOrder(1) )
		If SE1->( DBSeek( _cfilial + '1  ' + StrZero(Val(StrTran(_alinha[23],'"',"")),9) + '  NF') ) .And. SE1->E1_CLIENTE == '000578'
			
			aAdd(_aDados, {StrZero(Val(StrTran(_alinha[23],'"',"")),9),;  															//01 - num titulo
					 '01',;																							//02 - parcela
					 SE1->E1_CLIENTE,;																				//03 - codigo do cliente
					 SE1->E1_LOJA,;																					//04 - loja do cliente
					 mfin011z(_alinha[13]),;																			//05 - data de pagamento prevista
					 _aSm0[aScan( _aSm0, { |x| x[18] = (AllTrim(_alinha[7]))})][2],;			  				//06 - filial Italac
					 Posicione("SA1",1,xFilial("SA1") + SE1->E1_CLIENTE + SE1->E1_LOJA,"A1_CGC")})			//07 - CNPJ cliente
		
		EndIf
		
	EndIf
								                     
	FT_FSKIP()
	
EndDo
	
Return _aDados

/*
===============================================================================================================================
Programa----------: MFIN011L5
Autor-------------: Josué Danich Prestes
Data da Criacao---: 09/03/2016
Descrição---------: Faz a leitura de dados no layout do Cencosud
Parametros--------: _nreg - número de linhas do arquivo
					oproc2 - objeto da barra de processamento
Retorno-----------: _aDados - array com dados carregados do arquivo
===============================================================================================================================
*/

Static Function MFIN011L5(_nreg,oproc2)

Local	_nCont 	:= 0
Local _cdados		:= ""
Local _alinha		:= {}
Local _aDados 	:= {}
Local _aSM0 		:= FWLoadSM0()  //carrega array com dados de filiais
Default oproc2 := nil

FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
FT_FSKIP()

While !FT_FEOF()  //FACA ENQUANTO NAO For FIM DE ARQUIVO
	
	_nCont++ 

	If ValType(oproc2) = "O"

      	  oproc2:cCaption := ("Detectado arquivo Cencosud, Lendo linha " + StrZero(_nCont,5) + " de " + StrZero(_nreg,5) + ".")
   		  ProcessMessages()
 
    EndIf
			
	_cDados := FT_FREADLN() 
	_cDados := StrTran(_cdados,";",",")
	_cDados := StrTran(_cdados,'"','')
	_alinha := StrTokArr(_cDados,",")

			
	//Verifica se é linha válida
	If Len(_alinha) < 10
	
		FT_FSKIP()
		Loop
		
	EndIf			
	
	If Len(_alinha[1]) == 13 
	
		_alinha[1] := "0" + _alinha[1]
		
	EndIf
	
	If aScan( _aSm0, { |x| x[18] = (AllTrim(_alinha[1]))}) > 0	
	
		//Identifica filial
		_cfilial :=  _aSm0[aScan( _aSm0, { |x| x[18] = (AllTrim(_alinha[1]))})][2]
		
		//Usa número do título para identificar o cliente e loja
		DBSelectArea("SE1")
		SE1->( DBSetOrder(1) )
		If SE1->( DBSeek( _cfilial + '1  ' + StrZero(Val(SubStr(_alinha[2],1,Len(_alinha[2])-2)),9) + '  NF') ) 
		
			If AllTrim(SE1->E1_CLIENTE) == "001322" //Só adiciona títulos do cliente Cencosud 
			
				aAdd(_aDados, {StrZero(Val(SubStr(_alinha[2],1,Len(_alinha[2])-2)),9),;  									//01 - num titulo
					 '01',;																							//02 - parcela
					 SE1->E1_CLIENTE,;																				//03 - codigo do cliente
					 SE1->E1_LOJA,;																					//04 - loja do cliente
					 ctod(_alinha[8]),;																				//05 - data de pagamento prevista
					 _aSm0[aScan( _aSm0, { |x| x[18] = (AllTrim(_alinha[1]))})][2],;			  				//06 - filial Italac
					 Posicione("SA1",1,xFilial("SA1") + SE1->E1_CLIENTE + SE1->E1_LOJA,"A1_CGC")})			//07 - CNPJ cliente
		
			EndIf
		
		EndIf
		
	EndIf
								                     
	FT_FSKIP()
	
EndDo
	
Return _aDados

/*
===============================================================================================================================
Programa----------: MFIN011L6
Autor-------------: Josué Danich Prestes
Data da Criacao---: 09/03/2016
Descrição---------: Faz a leitura de dados no layout do Assai
Parametros--------: _nreg - número de linhas do arquivo
					oproc2 - objeto da barra de processamento
Retorno-----------: _aDados - array com dados carregados do arquivo
===============================================================================================================================
*/

Static Function MFIN011L6(_nreg,oproc2)

Local	_nCont 	:= 0
Local _cdados		:= ""
Local _alinha		:= {}
Local _aDados 	:= {}
Local _aSM0 		:= FWLoadSM0()  //carrega array com dados de filiais
Default oproc2 := nil

FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
FT_FSKIP()


While !FT_FEOF()  //FACA ENQUANTO NAO For FIM DE ARQUIVO
	
	_nCont++ 

	If ValType(oproc2) = "O"

      	  oproc2:cCaption := ("Detectado arquivo Assai, Lendo linha " + StrZero(_nCont,5) + " de " + StrZero(_nreg,5) + ".")
   		  ProcessMessages()
 
    EndIf
			
	_cDados := FT_FREADLN()    
	_cDados := StrTran(_cDados,'"','')
	_cDados := StrTran(_cDados,';',',')
	_alinha := StrTokArr(_cDados,",")

			
	//Verifica se é linha válida
	If Len(_alinha) < 7
	
		FT_FSKIP()
		Loop
		
	EndIf	 
	
	//Ajusta matriz
	If Len(_alinha) == 8
	
		_alinha[3] := AllTrim(Str(Val(_alinha[3]) + ( Val(_alinha[4]) /100 )))
		_alinha[4] := _alinha[5]
		_alinha[5] := _alinha[6]
		_alinha[6] := _alinha[7]    
		_alinha[7] := _alinha[8]
		
	EndIf

	
	//Ajusta CGC só com numeros 
	_alinha[1] := SubStr(_alinha[1],1,2) + SubStr(_alinha[1],4,3) + SubStr(_alinha[1],8,3) + SubStr(_alinha[1],12,4) + SubStr(_alinha[1],17,2)
			
	
	If aScan( _aSm0, { |x| x[18] = (AllTrim(_alinha[1]))}) > 0	
	
		//Identifica filial
		_cfilial :=  _aSm0[aScan( _aSm0, { |x| x[18] = (AllTrim(_alinha[1]))})][2]
		
		//Usa número do título para identificar o cliente e loja
		DBSelectArea("SE1")
		SE1->( DBSetOrder(1) )
		If SE1->( DBSeek( _cfilial + '1  ' + StrZero(Val(SubStr(_alinha[4],1,Len(_alinha[4])-2)),9) + '  NF') ) .And. (Posicione("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_GRPVEN") == '000008' .Or. SA1->A1_GRPVEN = '000010')
			
			aAdd(_aDados, {StrZero(Val(SubStr(_alinha[4],1,Len(_alinha[4])-2)),9),;  										//01 - num titulo
					 '01',;																							//02 - parcela
					 SE1->E1_CLIENTE,;																				//03 - codigo do cliente
					 SE1->E1_LOJA,;																					//04 - loja do cliente
					 ctod(_alinha[6]),;																				//05 - data de pagamento prevista
					 _aSm0[aScan( _aSm0, { |x| x[18] = (AllTrim(_alinha[1]))})][2],;			  				//06 - filial Italac
					 Posicione("SA1",1,xFilial("SA1") + SE1->E1_CLIENTE + SE1->E1_LOJA,"A1_CGC")})			//07 - CNPJ cliente
		
		EndIf
		
	EndIf
								                     
	FT_FSKIP()
	
EndDo
	
Return _aDados

/*
===============================================================================================================================
Programa----------: MFIN011L7
Autor-------------: Josué Danich Prestes
Data da Criacao---: 09/03/2016
Descrição---------: Faz a leitura de dados no layout do Makro
Parametros--------: _nreg - número de linhas do arquivo
					oproc2 - objeto da barra de processamento
Retorno-----------: _aDados - array com dados carregados do arquivo
===============================================================================================================================
*/

Static Function MFIN011L7(_nreg,oproc2)

Local	_nCont 	:= 0
Local _cdados		:= ""
Local _alinha		:= {}
Local _aDados 	:= {}
Default oproc2 := nil

FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
FT_FSKIP()


While !FT_FEOF()  //FACA ENQUANTO NAO For FIM DE ARQUIVO
	
	_nCont++ 

	If ValType(oproc2) = "O"

      	  oproc2:cCaption := ("Detectado arquivo Makro, Lendo linha " + StrZero(_nCont,5) + " de " + StrZero(_nreg,5) + ".")
   		  ProcessMessages()
 
    EndIf
			
	_cDados := FT_FREADLN()    
	_cDados := StrTran(_cDados,'"','')
	_cDados := StrTran(_cDados,';',',')
	_alinha := StrTokArr(_cDados,",")

	
	//Verifica se é linha válida
	If Len(_alinha) < 7 .Or. AllTrim(_alinha[3]) == '20334'
	
		FT_FSKIP()
		Loop
		
		
	EndIf	 
	
	
	//identifica filial do título
	_cQuery := "SELECT E1_FILIAL, E1_CLIENTE, E1_LOJA FROM " +retsqlname("SE1") + " SE1 WHERE D_E_L_E_T_ = ' '"
	_cQuery += " AND E1_NUM = '" + StrZero(Val(_alinha[1]),9) + "'"
	_cQuery += " AND E1_CLIENTE = '000444' AND E1_VALOR = '" + _alinha[9] + "'"
	_cQuery := ChangeQuery(_cQuery)
	MPSysOpenQuery(_cQuery,"SE1T")
	
	If SE1T->(!Eof())
			
			aAdd(_aDados, {StrZero(Val(_alinha[1]),9),;  															// 01 - num titulo
					 '01',;																							// 02 - parcela
					 SE1T->E1_CLIENTE,;																				// 03 - codigo do cliente
					 SE1T->E1_LOJA,;																				// 04 - loja do cliente
					 ctod(_alinha[11]),;																			// 05 - data de pagamento prevista
					 SE1T->E1_FILIAL,;			  																	// 06 - filial Italac
					 Posicione("SA1",1,xFilial("SA1") + SE1T->E1_CLIENTE + SE1T->E1_LOJA,"A1_CGC")})			    // 07 - CNPJ cliente
		
	EndIf
	
	SE1T->( DBCloseArea() )
								                     
	FT_FSKIP()
	
EndDo
	
Return _aDados

/*
===============================================================================================================================
Programa----------: MFIN011L8
Autor-------------: Julio de Paula Paz
Data da Criacao---: 11/08/2016
Descrição---------: Faz a leitura de dados no layout dos IRMAOS MUFFATO & CIA LTDA.
Parametros--------: _nreg - número de linhas do arquivo
					oproc2 - objeto da barra de processamento
Retorno-----------: _aDados - array com dados carregados do arquivo
===============================================================================================================================
*/
Static Function MFIN011L8(_nreg,oproc2)
Local _nCont 	:= 0
Local _cdados	:= ""
Local _alinha	:= {}
Local _aDados 	:= {}
Default oproc2 := nil

FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
FT_FSKIP()

While !FT_FEOF()  //FACA ENQUANTO NAO For FIM DE ARQUIVO
	
	_nCont++ 

	If ValType(oproc2) = "O"

      	  oproc2:cCaption := ("Detectado arquivo Irmãos Muffato & Cia Ltda. Lendo linha " + StrZero(_nCont,5) + " de " + StrZero(_nreg,5) + ".")
   		  ProcessMessages()
 
    EndIf
			
	_cDados := FT_FREADLN()    
	_cDados := StrTran(_cDados,'.','')
	_cDados := StrTran(_cDados,',','.')
	_cDados := StrTran(_cDados,'R$ ','')
	_cDados := StrTran(_cDados,';',',') 
	_cDados := StrTran(_cDados,',,',', ,')
	_alinha := StrTokArr(_cDados,",")

	//Verifica se é linha válida
	If Len(_alinha) < 8 
	   FT_FSKIP()
	   Loop
	EndIf	 
	
	//identifica filial do título
	_cQuery := "SELECT E1_FILIAL, E1_CLIENTE, E1_LOJA, E1_PARCELA FROM " +retsqlname("SE1") + " SE1 WHERE D_E_L_E_T_ = ' '"
	_cQuery += " AND E1_NUM = '" + StrZero(Val(_alinha[5]),9) + "'"
	_cQuery += " AND E1_CLIENTE = '004799' AND E1_VALOR = '" + _alinha[6] + "'"                // IRMAOS MUFFATO & CIA LTDA.
	_cQuery := ChangeQuery(_cQuery)
	MPSysOpenQuery(_cQuery,"SE1T")
	
	If SE1T->(!Eof())
			
			aAdd(_aDados, {StrZero(Val(_alinha[5]),9),;  															//01 - num titulo
					 SE1T->E1_PARCELA,;																				//02 - parcela
					 SE1T->E1_CLIENTE,;																				//03 - codigo do cliente
					 SE1T->E1_LOJA,;																				//04 - loja do cliente
					 ctod(_alinha[02]),;																			//05 - data de pagamento prevista
					 SE1T->E1_FILIAL,;			  																	//06 - filial Italac
					 Posicione("SA1",1,xFilial("SA1") + SE1T->E1_CLIENTE + SE1T->E1_LOJA,"A1_CGC")})		        //07 - CNPJ cliente
		
	EndIf
	
	SE1T->( DBCloseArea() )
								                     
	FT_FSKIP()
	
EndDo
	
Return _aDados

/*
===============================================================================================================================
Programa----------: MFIN011L9
Autor-------------: Julio de Paula Paz
Data da Criacao---: 12/08/2016
Descrição---------: Faz a leitura de dados no layout do Atacadão S/A
Parametros--------: _nreg - número de linhas do arquivo
					oproc2 - objeto da barra de processamento
Retorno-----------: _aDados - array com dados carregados do arquivo
===============================================================================================================================
*/
Static Function MFIN011L9(_nreg,oproc2)

Local _nCont 	:= 0
Local _cDados	:= ""
Local _alinha	:= {}
Local _lPosicInic := .F.
Local _lPrimColDados := .T.
Local _nPosInc
Local _nI		:= 0
Local _nPosFinal := 0
Local _cDado1 := ""   // 1) N Fiscal
Local _cDado2 := ""  // 2) Parc
Local _cDado3 := ""  // 3) CNPJ Fil
Local _cDado4 := ""  // 4) Valor
Local _cDado5 := ""  // 5) Filial
Local _cDado6 := ""  // 6) Emissao
Local _cDado7 := ""  // 7) Carenc
Local _cDado8 := ""  // 8) Receb.
Local _cDado9 := ""  // 9) Faturado
Local _cDado10 := "" // 10) Atras
Local _cDado11 := "" // 11) Prorrog.
Local _nItemDado := 1, _lIniciaCopy, _nIniColum, _nFinalColum
Local _cLinha := ""
Local _cTabela := ""
Default oproc2 := nil

Private _aDados 	:= {}

//===========================================================================
// Lê o arquivo HTML e monta uma variável do tipo String contendo apenas o 
// trecho a tabela de dados do arquivo Html.
//===========================================================================
FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO

While !FT_FEOF()  //FACA ENQUANTO NAO For FIM DE ARQUIVO      
    /*  Colunas da Tabela de dados do Atacadão S/A
    1) N Fiscal = Nr do Titulo
    2) Parc
    3) CNPJ Fil
    4) Valor
    5) Filial
    6) Emissao
    7) Carenc
    8) Receb.
    9) Faturado
    10) Atras
    11) Prorrog.    */
	
	_nCont++ 
	
	If ValType(oproc2) = "O"

      	  oproc2:cCaption := ("Detectado arquivo Atacadão S/A. Lendo linha " + StrZero(_nCont,5) + " de " + StrZero(_nreg,5) + ".")
   		  ProcessMessages()
 
    EndIf
			
	_cDados := FT_FREADLN()    
    
    If ! _lPosicInic
       If ! "<table" $ _cDados // Efetua a leitura do arquivo até achar a tag de inicio da tabela do Html.
          FT_FSKIP()
          Loop
       Else
          _lPosicInic := .T.
       EndIf
       
    EndIf           
    
    If _lPrimColDados
       If ! "Prorrog." $ _cDados // Efetua a leitura do arquivo até achar o título da ultima coluna da tabela.
          FT_FSKIP()
          Loop
       Else
          _lPrimColDados := .F.
       EndIf
    EndIf       
    
    //===========================================================================
    // O comando FT_FREADLN() possui limitação de tamanho e efetua cortes 
    // aleatórios no texto. Para evitar problemas na leitura de dados e para 
    // facilitar a identificação de inicio e termino de uma determinada tag,
    // todo o texto que envolve a tabela de dados do arquivo html é salvo na 
    // variável _cTabela.  
    //===========================================================================
    _cTabela += _cDados 
    
    _nPosFinal := At("</table>" ,_cDados, _nPosInc) // Após adicionar a linha com a tag de termino da tabela do arquivo html, encerra a leitura do arquivo html.    
    
    If _nPosFinal > 0
       Exit
    EndIf

   FT_FSKIP()
EndDo

_cDados := _cTabela

//===========================================================================
// Lê o arquivo Html separa os dados das tags html e monta o array,
// _aDados.
//===========================================================================
_nPosFinal := At("</table>" ,_cDados, _nPosInc)   // Identifica a posição final da tag de termino da tabela do arquivo html. 
_cLinha := ""
_nPosInc := At("<td bgColor" ,_cDados, _nPosInc)  // Identifica a posição inicial da primeira tag de dados da tabela do arquivo html.
_lIniciaCopy := .F. 

For _nI := _nPosInc To Len(_cDados)
    IncProc( "Lendo os dados enviados pelo Atacadão para atualização do Protheus.")
    
    If _nPosFinal > 0 .And. _nI >= _nPosFinal // Se a variável _nI ultrapassar a posição da tag de termino da tabela, encerra o processo de separação de dados e tags.
       Exit
    EndIf
                              
    If ! _lIniciaCopy // Se não iniciou a separação dos dados das tags html
       _nIniColum := At("<td bgColor" ,_cDados, _nI)  // localiza a posição inicial da proxima tag de dados.
       If _nIniColum == 0 
          Exit
       EndIf
       
       _nIniColum := At(">" ,_cDados, _nIniColum) // Localiza o termino da próxima tag de dados     
       _nI := _nIniColum + 1 // posiciiona no inicio do próximo dado a ser separado da tag.
           
       If _nI >= _nPosFinal .And. _nPosFinal > 0 // Indica que _nI chegou a posição da Tag de termino da tabela.
          Exit
       Else
          _lIniciaCopy := .T. // Indica que está na posição inicial para separação dos dados do arquivo Html, das tags.
       EndIf
    EndIf
        
    _nFinalColum := At("</td>" , _cDados, _nI) // Localiza a posição de termino da tag de dados.
    If _nI >= _nFinalColum  .And. _nFinalColum > 0 // Indica que a variável _nI chegou ao final dos dados a serem separados das tags do arquivo Html.
       _nItemDado += 1 // Indica que a leitura de dados deve ser feita na próxima coluna da tabela de dados do arquivo html.
       If _nItemDado > 11 // A tabela possui ao todo 11 colunas, quando a leitura termina a ultima coluna, volta para primeira coluna da linha seguinte.
          _nItemDado := 1
          _cLinha := _cDado1 +";"+_cDado2+";"+_cDado3+";"+_cDado4+";"+_cDado5+";"+_cDado6+";"+_cDado7+";"+_cDado8+";"+_cDado9+";"+_cDado10+";"+_cDado11 // Junta todas as colunas lidas do arquivo html em uma linha separada pro ";".
          _cLinha := StrTran(_cLinha,'.','')
	      _cLinha := StrTran(_cLinha,',','.')
	      _cLinha := StrTran(_cLinha,';',',') 
	      _cLinha := StrTran(_cLinha,',,',', ,')
	      _alinha := StrTokArr(_cLinha,",") // Após substituir alguns simbolos da variável _cLinha, transforma a variável _cLinha em Array.
          
          //===========================================================================
          // Esta função roda uma query na tabela de títulos SE1, com base no array 
          // _aLinha e grava o array _aDados.
          //===========================================================================
          MFIN011L9D(_alinha)  
          
          //===========================================================================
          // Após gravar o array _aDados, o conteúdo das variáveis a seguir, utilizadas
          // utilizadas para armazenar o conteúdo de cada linha da tabela de dados   
          // do arquivo html é limpo.
          //===========================================================================
          _cDado1 := ""  // 1) N Fiscal
          _cDado2 := ""  // 2) Parc
          _cDado3 := ""  // 3) CNPJ Fil
          _cDado4 := ""  // 4) Valor
          _cDado5 := ""  // 5) Filial
          _cDado6 := ""  // 6) Emissao
          _cDado7 := ""  // 7) Carenc
          _cDado8 := ""  // 8) Receb.
          _cDado9 := ""  // 9) Faturado
          _cDado10 := "" // 10) Atras
          _cDado11 := "" // 11) Prorrog.              
       EndIf       
           
       _lIniciaCopy := .F.
    EndIf
        
    If SubStr(_cDados,_nI,1) == ">" .Or. SubStr(_cDados,_nI,1) == "<"  // Se estiver posicionado no símbolo de inicio ou termino de tag, volta a ler  o próximo dado.
       Loop
    EndIf

    //===========================================================================
    // Digito a dígito, o conteúdo de cada coluna de dados é gravada na 
    // respectiva variável. 
    //===========================================================================       
    Do Case
       Case _nItemDado  == 1   // 1) N Fiscal
            If _lIniciaCopy                    
               _cDado1 += SubStr(_cDados,_nI,1)
            EndIf
       Case _nItemDado  == 2   // 2) Parc
            If _lIniciaCopy
               _cDado2 += SubStr(_cDados,_nI,1)        
            EndIf
       Case _nItemDado  == 3   // 3) CNPJ Fil
            If _lIniciaCopy
               _cDado3 += SubStr(_cDados,_nI,1)
            EndIf
       Case _nItemDado  == 4   // 4) Valor
            If _lIniciaCopy
               _cDado4 += SubStr(_cDados,_nI,1) 
            EndIf
       Case _nItemDado  == 5   // 5) Filial
            If _lIniciaCopy
               _cDado5 += SubStr(_cDados,_nI,1)
            EndIf
       Case _nItemDado  == 6   // 6) Emissao
            If _lIniciaCopy
               _cDado6 += SubStr(_cDados,_nI,1) 
            EndIf
       Case _nItemDado  == 7   // 7) Carenc
            If _lIniciaCopy
               _cDado7 += SubStr(_cDados,_nI,1)
            EndIf
       Case _nItemDado  == 8   // 8) Receb.
            If _lIniciaCopy
               _cDado8 += SubStr(_cDados,_nI,1)
            EndIf
       Case _nItemDado  == 9   // 9) Faturado
            If _lIniciaCopy
               _cDado9 += SubStr(_cDados,_nI,1)
            EndIf
       Case _nItemDado == 10  // 10) Atras
            If _lIniciaCopy
               _cDado10 += SubStr(_cDados,_nI,1)
            EndIf
       Case _nItemDado == 11  // 11) Prorrog.
            If _lIniciaCopy
              _cDado11  += SubStr(_cDados,_nI,1)
            EndIf
    EndCase   
Next _nI

//===========================================================================
// Se a ultima linha não For gravada no array _aDados, força a gravação 
// no array 
//===========================================================================
If _nItemDado > 1 .And. _nItemDado <= 11
   _cLinha := _cDado1 +";"+_cDado2+";"+_cDado3+";"+_cDado4+";"+_cDado5+";"+_cDado6+";"+_cDado7+";"+_cDado8+";"+_cDado9+";"+_cDado10+";"+_cDado11
   _cLinha := StrTran(_cLinha,'.','')
   _cLinha := StrTran(_cLinha,',','.')
   _cLinha := StrTran(_cLinha,';',',') 
   _cLinha := StrTran(_cLinha,',,',', ,')
   _alinha := StrTokArr(_cLinha,",")
              
   MFIN011L9D(_alinha)
EndIf
	
Return _aDados

/*
===============================================================================================================================
Programa----------: MFIN011L9D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 15/08/2016
Descrição---------: Faz a leitura de dados no layout do Atacadão S/A
                    Esta função monta os dados do Array _aDados
Parametros--------: _alinha - Array montado a partir da leitura do arquivo html.
					oproc2 - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MFIN011L9D(_alinha,oproc2)
Local _cQuery
Default oproc2 := nil

Begin Sequence

   //identifica filial do título
   _cQuery := "SELECT E1_FILIAL, E1_CLIENTE, E1_LOJA, E1_PARCELA FROM " +retsqlname("SE1") + " SE1 WHERE D_E_L_E_T_ = ' '"
   _cQuery += " AND E1_NUM = '" + StrZero(Val(_alinha[1]),9) + "'"
   _cQuery += " AND E1_CLIENTE = '000039' AND E1_VALOR = '" + _alinha[4] + "'"                // ATACADÃO S/A.
	_cQuery := ChangeQuery(_cQuery)
	MPSysOpenQuery(_cQuery,"SE1T")

   If SE1T->(!Eof())
			
      aAdd(_aDados, {StrZero(Val(_alinha[1]),9),;  															//01 - num titulo
					 SE1T->E1_PARCELA,;																		//02 - parcela
					 SE1T->E1_CLIENTE,;																		//03 - codigo do cliente
					 SE1T->E1_LOJA,;																		//04 - loja do cliente
					 ctod(_alinha[11]),;																	//05 - data de pagamento prevista
					 SE1T->E1_FILIAL,;			  															//06 - filial Italac
					 Posicione("SA1",1,xFilial("SA1") + SE1T->E1_CLIENTE + SE1T->E1_LOJA,"A1_CGC")})		//07 - CNPJ cliente
		
	EndIf
	
	SE1T->( DBCloseArea() )
								                     
End Sequence

Return

/*
===============================================================================================================================
Programa----------: MFIN011Z
Autor-------------: Josué Danich Prestes
Data da Criacao---: 15/08/2016
Descrição---------: Converte string de data do xls para data advpl
Parametros--------: _cdata - string com data
					oproc2 - objeto da barra de processamento
Retorno-----------: _ddata - data convertida
===============================================================================================================================
*/
Static Function MFIN011Z(_cdata,oproc2)

Local _ddata
Local _nI := 1
Local _cano := ""
Local _cmes := ""
Local _cdia := ""
Local _netapa := 1
Default oproc2 := nil

_cdata := AllTrim(_cdata)

While _nI <= Len(_cdata)

  If SubStr(_cdata,_nI,1) = "/"
    _netapa++
    _nI++
  EndIf
  
  If _nI > Len(_cdata)
    Exit
  EndIf

  If _netapa == 1
    _cdia := _cdia + SubStr(_cdata,_nI,1)
  EndIf

  If _netapa == 2
    _cmes := _cmes + SubStr(_cdata,_nI,1)
  EndIf
  
  If _netapa == 3
    _cano := _cano + SubStr(_cdata,_nI,1)
  EndIf
  
  _nI++  

EndDo

_ddata := ctod(StrZero(Val(_cdia),2)+"/"+StrZero(Val(_cmes),2)+"/"+_cano)

Return _ddata
