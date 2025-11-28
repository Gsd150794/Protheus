/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |08/05/2018| Chamado 24726. Padronização dos cabeçalhos dos fontes e funções do módulo financeiro.
Lucas Borges  |09/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Julio Paz     |08/03/2021| Chamado 35771. Incluir recurso para copiar arquivo gerado para o browse do usuário em acesso Web.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AFIN018 
Autor-------------: Fabiano
Data da Criacao---: 19/07/2010 
Descrição---------: Gera XML (Excel) de Titulos do Contas a Receber.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AFIN018()          
Local _cDirSmartC, aAux, _cFileTxt, _nI, _nTamTexto

Private cPerg:="AFIN018"
Private _cFilial,_dDtEmiIni,_dDtEmiFin,_dDtVenIni,_dDtVenFim,_cCliIni,_cCliFin,_cLojaIni,_cLojaFin,_cArquivo

If Pergunte(cPerg,.T.) 
 
	_cFilial	:= MV_PAR01
	_dDtEmiIni	:= DToS(MV_PAR02)
	_dDtEmiFin	:= DToS(MV_PAR03)
	_dDtVenIni	:= DToS(MV_PAR04)
	_dDtVenFim	:= DToS(MV_PAR05)
	_cCliIni    := MV_PAR06
	_cCliFin    := MV_PAR08    
	_cLojaIni   := MV_PAR07
	_cLojaFin   := MV_PAR09
	_cArquivo   := MV_PAR10 
	
    If Empty(_cArquivo)
       U_ITMsg( 'Nome do arquivo não informado!' , 'Atenção!' , , 1)
	   Break
	EndIf 

    _cDirSmartC := GetClientDir()
	  
	If Empty(_cDirSmartC) // Usuário utilizando SmartClient HTML
       aAux := separa(_cArquivo,".")
         
	   _nTamTexto := Len(aAux[1])
	   _cFileTxt  := ""
	   _nI := Rat("/",aAux[1])
		 
	   If _nI > 0
          _cFileTxt := SubStr(aAux[1],_nI+1,_nTamTexto)  
	   EndIf
         
	   If Empty(_cFileTxt)
          _nI := Rat("\",aAux[1])
		  If _nI > 0
             _cFileTxt := SubStr(aAux[1],_nI+1,_nTamTexto)  
		  EndIf
	   EndIf
         
	   If Empty(_cFileTxt)
          _cFileTxt := aAux[1]
	   EndIf
         
	   _cArquivo := "\Spool\"+AllTrim(_cFileTxt)
		
    EndIf

	Processa({|| Execute() },"Processando...")

    If Empty(_cDirSmartC) // Usuário utilizando SmartClient HTML

	   If File(_cArquivo)
          CpyS2TW(_cArquivo)  // Copia o arquivo para o Browse de navegação Web do usuário
	      Sleep(10000)  // 10 segundos
	   EndIf

    EndIf
	
EndIf            

Return

/*
===============================================================================================================================
Programa----------: Execute
Autor-------------: Fabiano
Data da Criacao---: 19/07/2010 
Descrição---------: Localiza Titulos e gera XML
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/                          
Static Function Execute()

Local oAlias 	:= GetNextAlias()             
Local cNome		:=""
Local aDados	:={}
Local aAux		:={}
Local nTotal	:=0
Local cFiltro   := ""

//=====================     
// Filtros
//=====================
If !Empty(_cFilial)
	cFiltro+=" AND E1.E1_FILIAL IN " + FormatIn(_cFilial,";")
EndIf

	cQuery:="SELECT" 
	cQuery+=" E1.E1_EMISSAO,E1.E1_VENCTO,E1.E1_NUM,E1.E1_PARCELA,E1.E1_CLIENTE,E1.E1_LOJA,"       
	cQuery+=" A1.A1_NOME,E1.E1_VALOR "
	cQuery+="FROM " + RETSQLNAME("SE1") + " E1 "   
	cQuery+=" JOIN " + RETSQLNAME("SA1") + " A1 ON E1.E1_CLIENTE = A1.A1_COD AND E1.E1_LOJA = A1.A1_LOJA "   
	cQuery+="WHERE" 
	cQuery+=" E1.D_E_L_E_T_ <> '*'"
	cQuery+=" AND A1.D_E_L_E_T_ <> '*'"
	cQuery+=" AND E1.E1_TIPO = 'NF '"
	cQuery+=" AND E1.E1_ORIGEM = 'MATA460'"
	cQuery+=" AND E1.E1_EMISSAO BETWEEN '" + _dDtEmiIni + "' AND '" + _dDtEmiFin + "'"
	cQuery+=" AND E1.E1_VENCTO BETWEEN '"  + _dDtVenIni + "' AND '" + _dDtVenFim + "'"
	cQuery+=" AND E1.E1_CLIENTE BETWEEN '" + _cCliIni   + "' AND '" + _cCliFin   + "'"
	cQuery+=" AND E1.E1_LOJA BETWEEN '"    + _cLojaIni  + "' AND '" + _cLojaFin  + "'"
	cQuery+= cFiltro   
	cQuery+=" ORDER BY"
	cQuery+=" E1.E1_VENCTO,E1.E1_NUM,E1.E1_PARCELA" 
	

dbUseArea( .T., "TOPCONN", TcGenQry(,,cQuery), oAlias, .T., .F. )
Count to nreg

ProcRegua(nreg)

(oAlias)->(DBGoTop())
                                                                   
aAdd( aDados , { "Emissao","Vencimento","Titulo/Parcela","Codigo Cliente","Razao Social","Valor" } )   
aAdd( aDados , { "","","","","","" })//Imprime Linhas em branco                     

While (oAlias)->(!Eof())                                     
	
		IncProc("Processando Titulo: " + AllTrim((oAlias)->E1_NUM))
	
		//==================================
		// Adiciona Dados no array
		//==================================
		cNome	 := RemovCar(AllTrim((oAlias)->A1_NOME))//Funcao que remove caracteres especiais para nao ocorrer erro na geracao do xml	      
		aAdd( aDados , {DToC(SToD((oAlias)->E1_EMISSAO)),DToC(SToD((oAlias)->E1_VENCTO)),(oAlias)->E1_NUM +'/'+(oAlias)->E1_PARCELA,;
					    (oAlias)->E1_CLIENTE +'-'+(oAlias)->E1_LOJA,cNome,(oAlias)->E1_VALOR})	
		
		nTotal+=(oAlias)->E1_VALOR 
		
		(oAlias)->(DBSkip())
		
	EndDo                             
	                        
	DBSelectArea(oAlias)
	(oAlias)->(DBCloseArea())
	
	//==================================
	// SubTotal e Total Geral
	//==================================
	aAdd( aDados , { ""     ,"","","","",""     }) // Imprime Linhas em branco 
	aAdd( aDados , { "Total","","","","",nTotal })
	
//==================================
// Converte Array em XML
//==================================
aAux	 := separa(_cArquivo,".")
_cArquivo:= AllTrim(aAux[1])+".xml"

RayToXml(aDados,_cArquivo)

Return

/*
===============================================================================================================================
Programa----------: RayToXml
Autor-------------: Abrahao P. Santos
Data da Criacao---: 22/12/2008 
Descrição---------: Cria um arquivo XML de um Array.                                      
                    Converte array para XLM. 
Parametros--------: aTabela = Array de dados.
                    cFileName = Nome do arquivo.
Retorno-----------: Nenhum
===============================================================================================================================
*/  
Static Function RayToXml(aTabela,cFileName)
                                    
Local y,i		:= 0
Private nHdlE	:= FCreate(cFileName)
Private cEOL	:= "CHR(13)+CHR(10)"

//==========================
// Cabecalho do XML
//==========================
cLin := '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?> '
cLin += '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" '
cLin += ' xmlns:o="urn:schemas-microsoft-com:office:office" '
cLin += ' xmlns:x="urn:schemas-microsoft-com:office:excel" '
cLin += ' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet" '
cLin += ' xmlns:html="http://www.w3.org/TR/REC-html40"> '
cLin += ' <Styles><Style ss:ID="Default" ss:Name="Normal"></Style><Style ss:ID="s21"><NumberFormat ss:Format="Short Date"/></Style></Styles> '
cLin += ' <Worksheet ss:Name="Planilha"><Table> '
FWrite(nHdlE,cLin,Len(cLin))

//==========================
// Convertendo Array
//==========================
For i:=1 to Len(aTabela)        
	//==========================
	// inicia linha
	//==========================
	cLin:="<Row>"
	FWrite(nHdlE,cLin,Len(cLin))
	
	For y:=1 to Len(aTabela[i])
		
		If ValType(aTabela[i,y]) == "N"
			cLin:='<Cell><Data ss:Type="Number">'+AllTrim(Str(aTabela[i,y]))+'</Data></Cell>'
		ElseIf ValType(aTabela[i,y]) == "D"
			cData:=DToS(aTabela[i,y])
		ElseIf ValType(aTabela[i,y]) == "C"
			cLin:='<Cell><Data ss:Type="String">'+aTabela[i,y]+'</Data></Cell>'  
		Else
			cLin:='<Cell><Data ss:Type="String">/Data></Cell>'	
		EndIf
		
		FWrite(nHdlE,cLin,Len(cLin))
		
	Next y
	//==========================
	// finaliza linha
	//==========================
	cLin:="</Row>"
	FWrite(nHdlE,cLin,Len(cLin))
	
Next i

//==========================
// Rodape do XML
//==========================
cLin := '</Table></Worksheet></Workbook>'
FWrite(nHdlE,cLin,Len(cLin))

FClose(nHdlE)

Return       

/*
===============================================================================================================================
Programa----------: RemovCar
Autor-------------: Fabiano Dias
Data da Criacao---: 18/06/2010
Descrição---------: Remove caractres especias para que nao gere erro ao gerar o xml.                                      
Parametros--------: Nenhum
Retorno-----------: cString = String com os caracteres especiais removidos.
===============================================================================================================================
*/
Static Function RemovCar(cString)

cString:= StrTran(cString,'&',"")
cString:= StrTran(cString,'<',"")
cString:= StrTran(cString,'>',"")
cString:= StrTran(cString,'%',"")
cString:= StrTran(cString,'~',"")
cString:= StrTran(cString,'^',"") 
cString:= StrTran(cString,'´',"")
cString:= StrTran(cString,'`',"")

Return cString                
