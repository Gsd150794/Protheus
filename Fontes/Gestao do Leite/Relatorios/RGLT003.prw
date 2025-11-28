/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
 Lucas Borges |25/07/2019| Chamado 28346. Revisão de fontes.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT003
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 24/05/2019
Descrição---------: Imprime notificação de Crioscopia. Chamado 29304
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT003()

Local cDesc1		:= "Este programa tem como objetivo imprimir carta "
Local cDesc2		:= "de crioscopia de acordo com as análises importadas."
Local cDesc3		:= ""
Local _cTitulo		:= "Carta de Crioscopia"
Local aOrd			:= {}
Private cTamanho	:= "P"
Private NomeProg	:= "RGLT003"
Private nTipo		:= 18
Private aReturn		:= { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
Private nLastKey	:= 0
Private m_pag		:= 01
Private wnrel		:= "RGLT003" // Coloque aqui o nome do arquivo usado para impressao em disco
Private _cPerg		:= "RGLT003"

Pergunte(_cPerg,.F.)

// Monta a interface padrao com o usuario...                           ³
wnrel := SetPrint("",NomeProg,_cPerg,@_cTitulo,cDesc1,cDesc2,cDesc3,.T.,aOrd,.T.,cTamanho,,.T.)

If nLastKey == 27
	Return
EndIf

SetDefault(aReturn,"")

If nLastKey == 27
   Return
EndIf

nTipo := If(aReturn[4]==1,15,18)

RptStatus({|| RGLT003P() },_cTitulo)

Return

/*
===============================================================================================================================
Programa----------: RGLT003P
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 24/05/2019
Descrição---------: Processa relatírio
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RGLT003P

Local nL			:= 0
Local nCount		:= 0
Local nPos1			:= 100
Local nPos2			:= 400
Local nPos3			:= 1500
Local nPos4			:= 1850
Local nTab01		:= 100
Local nTab02		:= 250
Local nTab03		:= 700
Local nTab04		:= 1100
Local nTab05		:= 1350
Local nTab06		:= 1650
Local nTab07		:= 1950

Local oFontTitulo	:= TFont():New("Arial",09,11,.T.,.T.,5,.T.,5,.T.,.F.)
Local oFontRotulo	:= TFont():New("Arial",09,10,.T.,.T.,5,.T.,5,.T.,.F.)
Local oFontNormal	:= TFont():New("Arial",09,09,.T.,.T.,5,.T.,5,.T.,.F.)

Local cRaizServer	:= If(issrvunix(), "/", "\")
Local nQtdReg		:= 0
Local _cAlias		:= GetNextAlias()
Local _aClass 		:= RetSX3Box(GetSX3Cache("A2_L_CLASS","X3_CBOX"),,,1)
Local _cFiltro		:= "%"
Local _nX			:= 0

OpenSm0(cEmpAnt, .F.)
SM0->(DBSeek(cEmpAnt + cFilAnt))
// Objeto de impressao grafica
oPrint:= TMSPrinter():New( "Relatorio de Grafico" )
oPrint:SetPortrait() 
oPrint:Setup()

//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR01) .Or. Empty(MV_PAR01) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro += " AND ZL3.ZL3_SETOR IN "+ FormatIn( AllTrim(MV_PAR01) , ';' )
EndIf

//Verifica se foi fornecido o filtro de linha
If !Empty(MV_PAR08)
	_cFiltro += " AND ZL3.ZL3_COD IN " + FormatIn(MV_PAR08,";")
EndIf

_cFiltro+= "%"
// Obtem dados de impressao
BeginSql alias _cAlias
  SELECT ZLB.ZLB_SETOR, ZL3.ZL3_COD, ZL3.ZL3_DESCRI, SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME, SA2.A2_CGC, SA2.A2_L_FAZEN, 
	  SA2.A2_INSCR, SA2.A2_MUN, SA2.A2_L_SIGSI, ZLB.ZLB_DATA, ZLA.ZLA_VALOR, ZLA.ZLA_FXINI, ZLA.ZLA_FXFIM, ZLB.ZLB_VLRFX, 
	  ZL3.ZL3_FRETIS, ZL3.ZL3_FRETLJ, SA2TRAN.A2_NOME NOME_TRAN, SA2.A2_L_TANQ, SA2.A2_L_TANLJ, SA2TQ.A2_NOME NOME_TANQUE, SA2.A2_L_CLASS,
	  ZLA.ZLA_DCRANA, ZLB.ZLB_VOLCRI AGUA, ZLD_QTDBOM-ZLB.ZLB_VOLCRI LEITE
  FROM %Table:ZLB% ZLB, %Table:ZLD% ZLD, %Table:ZLA% ZLA, %Table:SA2% SA2, %Table:ZL3% ZL3, %Table:SA2% SA2TRAN, %Table:SA2% SA2TQ
  WHERE ZLB.D_E_L_E_T_ = ' '
  AND ZLD.D_E_L_E_T_ = ' '
  AND ZLA.D_E_L_E_T_ = ' '
  AND SA2.D_E_L_E_T_ = ' '
  AND ZL3.D_E_L_E_T_ = ' '
  AND SA2TRAN.D_E_L_E_T_ = ' '
  AND SA2TQ.D_E_L_E_T_ = ' '
  AND ZLA.ZLA_FILIAL = %xFilial:ZLA%
  AND ZLB.ZLB_FILIAL = %xFilial:ZLB%
  AND ZLD.ZLD_FILIAL = %xFilial:ZLD%
  AND ZL3.ZL3_FILIAL = %xFilial:ZL3%
  %exp:_cFiltro%
  AND ZLB.ZLB_RETIRO BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR03%
  AND ZLB.ZLB_RETILJ BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR05%
  AND ZLB.ZLB_RETIRO = ZLD.ZLD_RETIRO
  AND ZLB.ZLB_RETILJ = ZLD.ZLD_RETILJ
  AND ZL3.ZL3_COD = ZLD.ZLD_LINROT
  AND SA2.A2_COD = ZLD.ZLD_RETIRO
  AND SA2.A2_LOJA = ZLD.ZLD_RETILJ
  AND SA2TRAN.A2_COD = ZL3.ZL3_FRETIS
  AND SA2TRAN.A2_LOJA = ZL3.ZL3_FRETLJ
  AND SA2TQ.A2_COD = SA2.A2_L_TANQ
  AND SA2TQ.A2_LOJA = SA2.A2_L_TANLJ
  AND ZLB.ZLB_SETOR = ZLD.ZLD_SETOR
  AND ZLB.ZLB_SETOR = ZLA.ZLA_SETOR
  AND ZLB.ZLB_TIPOFX = ZLA.ZLA_COD
  AND ZLA.ZLA_FXINI <= ZLB_VLRFX
  AND ZLA.ZLA_FXFIM >= ZLB_VLRFX
  AND ZLB.ZLB_DATA BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR07%
  AND ZLD.ZLD_DTCOLE = ZLB.ZLB_DATA
  AND ZLB.ZLB_TIPOFX = '000012'
  ORDER BY SA2.A2_COD, SA2.A2_LOJA, ZLB.ZLB_DATA
EndSql
Count to nQtdReg

ProcRegua(nQtdReg)

(_cAlias)->(DBGoTop())
While !(_cAlias)->(Eof())
	nCount++                   

	IncProc((_cAlias)->A2_COD)
	For _nX:= 1 To 2
	    oPrint:StartPage()
	    
		//===================================================================
		// Início Cabecalho
		//===================================================================
		nL := 50
		oPrint:FillRect({nL,2300,nL+1,100},TBrush():New("",0)) 
	   	oPrint:SayBitmap(nL+20,100,cRaizServer + "system/lgrl01.bmp",250,100)
		nL += 10
		oPrint:Say(nL,2000,"Emissão:"+DToC(DDataBase),oFontNormal) 
		nL += 50
	
		oPrint:Say(nL,1000,"Carta de Não Conformidade",oFontTitulo)
	
		oPrint:Say(nL,2000,"Paginas: "+cValtoChar(_nX)+"/2 ",oFontNormal) 
		nL += 50
		oPrint:Say(nL,2000,"Hora:"+time(),oFontNormal) 
		nL += 50
		oPrint:FillRect({nL,2300,nL+1,100},TBrush():New("",0)) 
		nL += 10
		//===================================================================
		// Fim Cabecalho
		//===================================================================
	
		//===================================================================
		// Início dos dados da Empresa
		//===================================================================
		oPrint:Say(nL,nPos1,AllTrim(SM0->M0_NOME)+"-"+AllTrim(SM0->M0_FILIAL)+"-"+SM0->M0_NOMECOM,oFontRotulo) 
		oPrint:Say(nL,nPos3,"CNPJ:"+SM0->M0_CGC,oFontRotulo) 
		nL += 50
		oPrint:Say(nL,nPos1,AllTrim(SM0->M0_ENDENT)+"-"+AllTrim(SM0->M0_CIDENT)+"-"+AllTrim(SM0->M0_ESTENT),oFontRotulo) 
		nL += 50
		oPrint:FillRect({nL,2300,nL+1,100},TBrush():New("",0)) 
		nL += 10
		//===================================================================
		// Fim dos dados da Empresa
		//===================================================================
			
		//===================================================================
		// Início dos dados do Produtor
		//===================================================================
		nL += 50
		oPrint:Say(nL,nPos1,"PRODUTOR:",oFontRotulo) 
		oPrint:Say(nL,nPos2,(_cAlias)->A2_COD+"/"+(_cAlias)->A2_LOJA+" - "+(_cAlias)->A2_NOME,oFontNormal) 
		oPrint:Say(nL,nPos3,"CPF:",oFontRotulo)
		oPrint:Say(nL,nPos4,(_cAlias)->A2_CGC,oFontNormal)
	
		nL += 50
		oPrint:Say(nL,nPos1,"FAZENDA:",oFontRotulo) 
		oPrint:Say(nL,nPos2,(_cAlias)->A2_L_FAZEN,oFontNormal) 
		oPrint:Say(nL,nPos3,"INSCRICAO:",oFontRotulo)
		oPrint:Say(nL,nPos4,(_cAlias)->A2_INSCR,oFontNormal)
			
		nL += 50
		oPrint:Say(nL,nPos1,"MUNICIPIO:",oFontRotulo) 
		oPrint:Say(nL,nPos2,(_cAlias)->A2_MUN,oFontNormal) 
		oPrint:Say(nL,nPos3,"SIGSIF:",oFontRotulo)
		oPrint:Say(nL,nPos4,(_cAlias)->A2_L_SIGSI,oFontNormal)
	
		nL += 50
		oPrint:Say(nL,nPos1,"LINHA:",oFontRotulo) 
		oPrint:Say(nL,nPos2,(_cAlias)->ZL3_COD+" - "+(_cAlias)->ZL3_DESCRI,oFontNormal) 

		nL += 50
		oPrint:Say(nL,nPos1,"FRETISTA:",oFontRotulo)
			
		oPrint:Say(nL,nPos2, (_cAlias)->ZL3_FRETIS +'/'+ (_cAlias)->ZL3_FRETLJ +" - "+ (_cAlias)->NOME_TRAN , oFontNormal )
		oPrint:Say(nL,nPos3,"",oFontRotulo)
		oPrint:Say(nL,nPos4,"",oFontNormal)
			
		nL += 50
		oPrint:Say(nL,nPos1,"RESP.TANQUE:",oFontRotulo) 
		oPrint:Say(nL,nPos2,(_cAlias)->A2_L_TANQ +'/'+ (_cAlias)->A2_L_TANLJ +" - "+ (_cAlias)->NOME_TANQUE , oFontNormal ) //Ajuste para considerar a Loja no posicionamento e exibição [Chamado-6851]
			
		oPrint:Say(nL,nPos3,"CLASS.TANQUE:",oFontRotulo)
		oPrint:Say(nL,nPos4,_aClass[aScan(_aClass,{|x| x[2] == (_cAlias)->A2_L_CLASS})][3],oFontNormal) 
	
		nL += 50
		oPrint:FillRect({nL,2300,nL+1,100},TBrush():New("",0)) 
		//===================================================================
		// Fim dos dados do Produtor
		//===================================================================
		nL += 100
		oPrint:Say(nL,nPos1,"Em conformidade com as instruções normativas 76 e 77 do Ministério da Agricultura Pecuária e Abastecimento (MAPA) publicadas",oFontRotulo)
		nL += 50
		oPrint:Say(nL,nPos1,"no dia 30/11/2018, após analisar a amostra do leite coletado em sua propriedade no dia "+DToC(SToD((_cAlias)->ZLB_DATA))+", a mesma apresentou fora dos",oFontRotulo)
		nL += 50
		oPrint:Say(nL,nPos1,"padrões para o(s) seguinte(s) requisito(s) "+AllTrim((_cAlias)->ZLA_DCRANA)+".",oFontRotulo)
	
		//===================================================================
		// Início do quadro da análise
		//===================================================================
		nL += 150
		oPrint:Say(nL,900,"Padrões de recebimento",oFontRotulo)
		nL += 50
		oPrint:FillRect({nL,2300,nL+1,100},TBrush():New("",0)) 
		nL += 10
		oPrint:Say(nL	,nTab01,"Data",oFontRotulo)
		oPrint:Say(nL	,nTab02,"Requisito",oFontRotulo)
		oPrint:Say(nL	,nTab03,"Padrão  ",oFontRotulo)
		oPrint:Say(nL	,nTab04,"Resultado",oFontRotulo)
		oPrint:Say(nL+50,nTab04,"Amostra",oFontRotulo)
		oPrint:Say(nL	,nTab05,"Volume total",oFontRotulo)
		oPrint:Say(nL+50,nTab05,"de Leite",oFontRotulo)
		oPrint:Say(nL	,nTab06,"Porcentagem",oFontRotulo)
		oPrint:Say(nL+50,nTab06,"de Água (%)",oFontRotulo)
		oPrint:Say(nL	,nTab07,"Volume total",oFontRotulo)
		oPrint:Say(nL+50,nTab07,"de água descontado",oFontRotulo)
		nL += 100
		oPrint:FillRect({nL,2300,nL+1,100},TBrush():New("",0)) 
		nL += 10
		oPrint:Say(nL,nTab01,DToC(SToD((_cAlias)->ZLB_DATA)),oFontRotulo)
		oPrint:Say(nL,nTab02,AllTrim((_cAlias)->ZLA_DCRANA),oFontRotulo)
		oPrint:Say(nL,nTab03,Transform((_cAlias)->ZLA_FXINI,"@E 99.999")+ "º H a " + Transform((_cAlias)->ZLA_FXFIM,"@E 9.999")+ "º H",oFontNormal)
		oPrint:Say(nL,nTab04,Transform((_cAlias)->ZLB_VLRFX,"@E 99.999"),oFontNormal)
		oPrint:Say(nL,nTab05,Transform((_cAlias)->LEITE,"@E 999,999"),oFontNormal)
		oPrint:Say(nL,nTab06,Transform((_cAlias)->ZLA_VALOR,"@E 99.9"),oFontNormal)
		oPrint:Say(nL,nTab07,Transform((_cAlias)->AGUA,"@E 999,999"),oFontNormal)
		nL += 50 
		oPrint:FillRect({nL,2300,nL+1,100},TBrush():New("",0)) 
	
		nL += 10
		//===================================================================
		// Fim do quadro da análise
		//===================================================================
	
		//===================================================================
		// Início das assinaturas
		//===================================================================
		nL += 200
		oPrint:Say(nL,nPos1,"Solicitamos providências imediatas para que o problema seja sanado de vez.",oFontRotulo)
		nL += 250
		oPrint:FillRect({nL,500,nL+1,2000},TBrush():New("",0)) 
		oPrint:Say(nL,900,"Departamento de Suprimento e Fomento - Italac",oFontRotulo)
	
		nL += 250
		oPrint:FillRect({nL,500,nL+1,2000},TBrush():New("",0)) 
		oPrint:Say(nL,900,"Transportador",oFontRotulo)	
	
		nL += 250
		oPrint:FillRect({nL,500,nL+1,2000},TBrush():New("",0)) 
		oPrint:Say(nL,900,"Produtor",oFontRotulo)
		
		nL += 150
		oPrint:Say(nL,900,"Data:  ____/____/____",oFontRotulo)
	
		nL += 100
		oPrint:Say(nL,nPos1,"Qualquer dúvida, estamos à disposição para marcarmos visitas técnicas na melhoria da qualidade do seu leite.",oFontRotulo)
		nL += 10
		//===================================================================
		// Fim das assinaturas
		//===================================================================
		
		oPrint:EndPage()
	Next _nX
	(_cAlias)->(DBSkip())
	
EndDo
(_cAlias)->(DBCloseArea())
	
oPrint:Preview()

Return
