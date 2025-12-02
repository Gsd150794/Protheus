#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: RFIN008
Autor-----------: Fabiano Dias
Data da Criacao-: 30/07/2010
Descrição-------: Relatorio financeiro que demonstra o Resumo de Contas a Pagar de acordo com os parametros informados
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function RFIN008()

Private oFont09     
Private oFont09b
Private oFont10
Private oFont10b
Private oFont12
Private oFont12b  
Private oFont16b           
Private oFont14
Private oFont14b

Private oPrint

Private nPagina     := 0

Private nLinha      := 0100
Private nColInic    := 0030
Private nColFinal   := 2360 
Private nqbrPagina  := 3300 
Private nLinInBox   
Private nSaltoLinha := 50               
Private nAjuAltLi1  := 10 //ajusta a altura de impressao dos dados do relatorio

Private oBrush      := TBrush():New( ,CLR_LIGHTGRAY)   

Private cPerg       := "RFIN008"      

Private horaImp     := Time()

Private _lAglutFil  //Aglutina por Filial - 1 == SIM - 2 == NAO 
Private _lAglutTit  //Aglutina por Titulo - 1 == SIM - 2 == NAO
Private _lCalSldDt  //Compoe saldo do titulo For iguar a Nao(2), ou seja, nao calcula saldo do titulo de acordo com a data informada pelo usuario e sim pelo saldo atual
Private _dDtBase    //Data a ser considerada para calculo do sado dos Titulos
Private _lTitFluxo  //Considera somente titulos que entram no fluxo de caixa 1 == SIM 2 == NAO
Private _rFiliais   //Filiais informadas pelo usuario
Private _dDtEmisIn  //Data de Emissao Inicial
Private _dDtEmisFi  //Data de Emissao Final
Private _dDtVencIn  //Data de Vencimento Inicial
Private _dDtVencFi  //Data de Vencimento Final       
Private _rTipTitIn  //Tipo dos titulos a considerar na selecao dos registro
Private _rTipTitOu  //Tipo dos titulos a nao considerar na selecao dos registros
Private _cCodForIn  //Codigo Inicial do Fornecedor
Private _cCodForFi  //Codigo Inicial do Fornecedor 
Private _cLojForIn  //Codigo da Loja Inicial do Fornecedor 
Private _cLojForFi  //Codigo da Loja Final do Fornecedor     
Private _rNatImpri  //Codigo das naturezas que sejam iguais as informadas
Private _rNatNImpr  //Codigo das naturezas que sejam diferentes as informadas
Private _nGerExcel := 2

Begin Sequence

   If !Pergunte(cPerg,.T.) 
      Break
   EndIf

   // PARAMETROS      
   _lAglutFil:= MV_PAR01 == 1  //Aglutina por Filial - 1 == SIM - 2 == NAO 
   _lAglutTit:= MV_PAR02 == 1  //Aglutina por Titulo - 1 == SIM - 2 == NAO
   _lCalSldDt:= MV_PAR03 == 1  //Compoe saldo do titulo For iguar a Nao(2), ou seja, nao calcula saldo do titulo de acordo com a data informada pelo usuario e sim pelo saldo atual
   _dDtBase  := MV_PAR04       //Data a ser considerada para calculo do sado dos Titulos
   _lTitFluxo:= MV_PAR05 == 1  //Considera somente titulos que entram no fluxo de caixa 1 == SIM 2 == NAO
   _rFiliais := MV_PAR06       //Filiais informadas pelo usuario
   _dDtEmisIn:= DToS(MV_PAR07) //Data de Emissao Inicial
   _dDtEmisFi:= DToS(MV_PAR08) //Data de Emissao Final
   _dDtVencIn:= DToS(MV_PAR09) //Data de Vencimento Inicial
   _dDtVencFi:= DToS(MV_PAR10) //Data de Vencimento Final       
   _rTipTitIn:= MV_PAR11       //Tipo dos titulos a considerar na selecao dos registro
   _rTipTitOu:= MV_PAR12       //Tipo dos titulos a nao considerar na selecao dos registros
   _cCodForIn:= MV_PAR13       //Codigo Inicial do Fornecedor
   _cCodForFi:= MV_PAR15       //Codigo Final do Fornecedor 
   _cLojForIn:= MV_PAR14       //Codigo da Loja Inicial do Fornecedor 
   _cLojForFi:= MV_PAR16       //Codigo da Loja Final do Fornecedor     
   _rNatImpri:= MV_PAR17       //Codigo das naturezas que sejam iguais as informadas
   _rNatNImpr:= MV_PAR18       //Codigo das naturezas que sejam diferentes as informadas
   _nGerExcel:= MV_PAR19       //Gera Relatório em Excel - 1 == SIM - 2 == NAO 

   If _nGerExcel <> 1 // Relatório Impresso
      Define Font oFont09    Name "Courier New"       Size 0,-07       // Tamanho 14                                                                              
      Define Font oFont09b   Name "Courier New"       Size 0,-07 Bold  // Tamanho 14                                                                              
      Define Font oFont10    Name "Courier New"       Size 0,-08       // Tamanho 14    
      Define Font oFont10b   Name "Courier New"       Size 0,-08 Bold   // Tamanho 14 
      Define Font oFont12    Name "Courier New"       Size 0,-10       // Tamanho 12
      Define Font oFont12b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 12 Negrito  
      Define Font oFont14    Name "Courier New"       Size 0,-10       // Tamanho 14
      Define Font oFont14b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 14         
      Define Font oFont14Prb Name "Courier New"       Size 0,-12 Bold  // Tamanho 14 Negrito  

      oPrint:= TMSPrinter():New("RESUMO DE CONTAS A PAGAR") 
      oPrint:SetPortrait() 	// Retrato  oPrint:SetLandscape() - Paisagem
      oPrint:SetPaperSize(9)	// Seta para papel A4
	                 		
      /// startando a impressora
      oPrint:Say(0,0," ",oFont12,100)        

      oPrint:StartPage() 
   EndIf

   If _nGerExcel <> 1 // Relatório Impresso
      //0 - para nao imprimir a numeracao de pagina na emissao da pagina de parametros
      RFIN008C(0)
      RFIN008IP(oPrint)
   EndIf		     		 	

   Processa({|| RFIN008DR() })  

   If _nGerExcel <> 1 // Relatório Impresso	
      oPrint:EndPage()	// Finaliza a Pagina.
      oPrint:Preview()	// Visualiza antes de Imprimir.
   EndIf

End Sequence

Return

/*
===============================================================================================================================
Programa--------: RFIN008C
Autor-----------: Fabiano Dias
Data da Criacao-: 30/07/2010
Descrição-------: Função que imprime o cabeçalho do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RFIN008C(impNrPag,cDescFil)    

Local cRaizServer := If(issrvunix(), "/", "\")    
Local cTitulo     := "RESUMO DE CONTAS A PAGAR - " + AllTrim(cDescFil) + ' De ' + DToC(SToD(_dDtVencIn)) + ' à ' + DToC(SToD(_dDtVencFi))

nLinha      := 0100
 
	oPrint:SayBitmap(nLinha,nColInic,cRaizServer + "system/lgrl01.bmp",250,100)      
	  
	If impNrPag <> 0
		oPrint:Say (nlinha,nColFinal - 550,"PÁGINA: " + AllTrim(Str(nPagina)),oFont12b)
		Else
			oPrint:Say (nlinha,nColFinal - 550,"SIGA/RFIN008",oFont12b)
			oPrint:Say (nlinha + 150,nColFinal - 550,"EMPRESA: " + AllTrim(SM0->M0_NOME) + '/' + AllTrim(SM0->M0_FILIAL),oFont12b)
	EndIf
	oPrint:Say (nlinha + 50 ,nColFinal - 550,"DATA DE EMISSÃO: " + DToC(DATE()),oFont12b)   
	oPrint:Say (nlinha + 100,nColFinal - 550,"HORA: " + horaImp                ,oFont12b)
	nlinha+=(nSaltoLinha * 3)           
	                                                   
	oPrint:Say (nlinha,nColFinal / 2,cTitulo,oFont16b,nColFinal,,,2)
	
	nlinha+=nSaltoLinha 
	nlinha+=nSaltoLinha        
	
	oPrint:Line(nLinha,nColInic,nLinha,nColFinal) 

Return                                               

/*
===============================================================================================================================
Programa--------: RFIN008D
Autor-----------: Fabiano Dias
Data da Criacao-: 30/07/2010
Descrição-------: Função que imprime o cabeçalho dos dados do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RFIN008D()    
                  
nLinInBox:= nlinha        

oPrint:FillRect({(nlinha+3),nColInic  ,nlinha + nSaltoLinha,nColFinal},oBrush)//Box Faturamento 

oPrint:Say (nlinha + nAjuAltLi1,nColInic + 20	    ,"DIA"     ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColFinal - 130    ,"VALOR"   ,oFont12b)   

nlinha+=nSaltoLinha   
oPrint:Line(nLinha,nColInic,nLinha,nColFinal) 

Return      

/*
===============================================================================================================================
Programa--------: RFIN008P
Autor-----------: Fabiano Dias
Data da Criacao-: 30/07/2010
Descrição-------: Função que imprime os dados do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RFIN008P(sDtDia,nValor)

oPrint:Say (nlinha + nAjuAltLi1,nColInic	 + 20 ,DToC(SToD(sDtDia))   					 ,oFont12)
oPrint:Say (nlinha + nAjuAltLi1,nColFinal - 410,Transform(nValor,"@E 999,999,999,999.99")   ,oFont12)

Return     

/*
===============================================================================================================================
Programa--------: RFIN008T
Autor-----------: Fabiano Dias
Data da Criacao-: 30/07/2010
Descrição-------: Função que imprime os dados de totalizadores do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RFIN008T(cDescri,nValor)

oPrint:Say (nlinha + nAjuAltLi1,nColInic	 + 20 ,cDescri              					 ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColFinal - 410,Transform(nValor,"@E 999,999,999,999.99")   ,oFont12b)

Return          

/*
===============================================================================================================================
Programa--------: RFIN008B
Autor-----------: Fabiano Dias
Data da Criacao-: 30/07/2010
Descrição-------: Função que imprime os box de divisão do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RFIN008B()
      
oPrint:Line(nLinInBox,nColInic + 300,nLinha+nSaltoLinha,nColInic + 300)   
oPrint:Box(nLinInBox ,nColInic      ,nLinha+nSaltoLinha,nColFinal     ) //Box Totalizador Descontos

Return     

/*
===============================================================================================================================
Programa--------: RFIN008F
Autor-----------: Fabiano Dias
Data da Criacao-: 30/07/2010
Descrição-------: Função que imprime o cabeçalho de dados do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RFIN008F()    
                  
nLinInBox:= nlinha        

oPrint:FillRect({(nlinha+3),nColInic  ,nlinha + nSaltoLinha,nColFinal},oBrush)//Box Faturamento 

oPrint:Say (nlinha + nAjuAltLi1,nColInic + 20	    ,"FORNECEDOR" ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColFinal/2	        ,"NATUREZA"   ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColFinal - 130    ,"VALOR"      ,oFont12b)   

nlinha+=nSaltoLinha   
oPrint:Line(nLinha,nColInic,nLinha,nColFinal) 

Return        

/*
===============================================================================================================================
Programa--------: RFIN008FP
Autor-----------: Fabiano Dias
Data da Criacao-: 30/07/2010
Descrição-------: Função que imprime os dados do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RFIN008FP(cFornec,cNatureza,nValor)    

oPrint:Say (nlinha + nAjuAltLi1,nColInic + 20	    ,SubStr(cFornec,1,50)						 ,oFont12)
oPrint:Say (nlinha + nAjuAltLi1,nColFinal/2	        ,SubStr(cNatureza,1,36)						 ,oFont12) 
oPrint:Say (nlinha + nAjuAltLi1,nColFinal - 410    ,Transform(nValor,"@E 999,999,999,999.99")   ,oFont12)

Return                     

/*
===============================================================================================================================
Programa--------: RFIN008FB
Autor-----------: Fabiano Dias
Data da Criacao-: 30/07/2010
Descrição-------: Função que imprime os box de divisão do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RFIN008FB()
      
oPrint:Line(nLinInBox,(nColFinal/2) - 10,nLinha+nSaltoLinha,(nColFinal/2) - 10)   
oPrint:Line(nLinInBox,nColFinal - 385   ,nLinha+nSaltoLinha,nColFinal - 385)
oPrint:Box(nLinInBox ,nColInic          ,nLinha+nSaltoLinha,nColFinal) //Box Totalizador Descontos

Return     

/*
===============================================================================================================================
Programa--------: RFIN008N
Autor-----------: Fabiano Dias
Data da Criacao-: 30/07/2010
Descrição-------: Função que imprime o cabeçalho de dados do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RFIN008N()    
                  
nLinInBox:= nlinha        

oPrint:FillRect({(nlinha+3),nColInic  ,nlinha + nSaltoLinha,nColFinal},oBrush)//Box Faturamento 

oPrint:Say (nlinha + nAjuAltLi1,nColInic + 20	    ,"NATUREZA" ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColFinal - 130    ,"VALOR"    ,oFont12b)   

nlinha+=nSaltoLinha   
oPrint:Line(nLinha,nColInic,nLinha,nColFinal) 

Return      

/*
===============================================================================================================================
Programa--------: RFIN008NP
Autor-----------: Fabiano Dias
Data da Criacao-: 30/07/2010
Descrição-------: Função que imprime os dados do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RFIN008NP(cNatureza,nValor)

oPrint:Say (nlinha + nAjuAltLi1,nColInic	 + 20 ,SubStr(cNatureza,1,70)  					   ,oFont12)
oPrint:Say (nlinha + nAjuAltLi1,nColFinal - 410  ,Transform(nValor,"@E 999,999,999,999.99")   ,oFont12)

Return                    

/*
===============================================================================================================================
Programa--------: RFIN008NB
Autor-----------: Fabiano Dias
Data da Criacao-: 30/07/2010
Descrição-------: Função que imprime os box de divisão do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RFIN008NB()
      
oPrint:Line(nLinInBox,(nColFinal/2) + 450,nLinha+nSaltoLinha,(nColFinal/2) + 450)   
oPrint:Box(nLinInBox ,nColInic           ,nLinha+nSaltoLinha,nColFinal) //Box Totalizador Descontos

Return     

/*
===============================================================================================================================
Programa--------: RFIN008DR
Autor-----------: Fabiano Dias
Data da Criacao-: 30/07/2010
Descrição-------: Função que imprime os dados do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RFIN008DR()  

Local _cQuery     := "" 
Local _cFiltro    := ""   
Local y				:= 0
Local nMoeda	  := 1
Local nCountRec   := 0  
   
Local _aAreaGer   := FWGetArea()       

Local nJurTit     := 0

Local _cTitulo

//Armazena as Filiais encontradas para que caso a opcao nao aglutinar por Filial esteja marcada como nao,
//imprimir os 3 tipos do relatorio por Filial, para depois imprimir outra Filial                                                                
Private _aFilial  := {} 
                     
Private _cAliasSE2:= GetNextAlias()
 
Private _nSaldoTit:= 0   			 //Variavel responsavel por armazenar o saldo de cada titulo selecionado na query

Private _aDiasVenc:= {}  			 //Array que armazena os dados dos titulos a pagar por Data de Pagamento + Tipo do Titulo(NDF - Negativo) ou demais tipos
Private _aForn    := {}				//Array que armazena os dados dos titulos a pagar por Data de Vencimento + Tipo do Titulo (NDF + outros) + Fornecedor + Natureza
Private _aNatureza:= {}				//Arrya que armazena os dados dos titulos a pagar po Natureza + Tipo do Titulo(NDF + outros))

Private _aCabRelDia := {}
Private _aDadosRDia := {}

Private _aCabRelTit := {}
Private _aDadosRTit := {}

Private _aCabRelNat := {}
Private _aDadosRNat := {}
Private _aCabecPlanilha, _aDetalhePlanilha

Begin Sequence  
   _aCabecPlanilha := {}
   _aDetalhePlanilha := {}

   _aCabRelDia := {} // Array com o cabeçalho das colunas do relatório. 
   // Alinhamento( 1-Left,2-Center,3-Right )
   // Formatação( 1-General,2-Number,3-Monetário,4-DateTime )
   //                  Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?  
   aAdd(_aCabRelDia,{"FILIAL"             ,1           ,1         ,.F.})
   aAdd(_aCabRelDia,{"NOME FILIAL"        ,1           ,1         ,.F.})
   aAdd(_aCabRelDia,{"DIA"                ,2           ,4         ,.F.})    
   aAdd(_aCabRelDia,{"VALOR"              ,3           ,3         ,.F.})   

   _aCabRelTit := {} // Array com o cabeçalho das colunas do relatório. 
   // Alinhamento( 1-Left,2-Center,3-Right )
   // Formatação( 1-General,2-Number,3-Monetário,4-DateTime )
   //                  Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?  
   aAdd(_aCabRelTit,{"DIA"                ,2           ,4         ,.F.}) 
   aAdd(_aCabRelTit,{"FILIAL"             ,1           ,1         ,.F.})     
   aAdd(_aCabRelTit,{"NOME FILIAL"        ,1           ,1         ,.F.})    
   aAdd(_aCabRelTit,{"FORNECEDOR"         ,1           ,1         ,.F.})    
   aAdd(_aCabRelTit,{"NOME FORNECEDOR"    ,1           ,1         ,.F.})    
   aAdd(_aCabRelTit,{"NATUREZA"           ,1           ,1         ,.F.})    
   aAdd(_aCabRelTit,{"DESC.NATUREZA"      ,1           ,1         ,.F.})    
   aAdd(_aCabRelTit,{"VALOR"              ,3           ,3         ,.F.}) 

   _aCabRelNat := {} // Array com o cabeçalho das colunas do relatório. 
   // Alinhamento( 1-Left,2-Center,3-Right )
   // Formatação( 1-General,2-Number,3-Monetário,4-DateTime )
   //                  Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?  
   aAdd(_aCabRelNat,{"FILIAL"             ,1           ,1         ,.F.})    
   aAdd(_aCabRelNat,{"NOME FILIAL"        ,1           ,1         ,.F.})    
   aAdd(_aCabRelNat,{"NATUREZA"           ,1           ,1         ,.F.})    
   aAdd(_aCabRelNat,{"DESC.NATUREZA"      ,1           ,1         ,.F.})             
   aAdd(_aCabRelNat,{"VALOR"              ,3           ,3         ,.F.})    

   aAdd(_aCabecPlanilha, {"Por dia de Pagamento",_aCabRelDia})
   aAdd(_aCabecPlanilha, {"Por dia de Pagamento + Fornecedor + Natureza",_aCabRelTit})
   aAdd(_aCabecPlanilha, {"Por Natureza", _aCabRelNat})

   //FILTROS
   //FILIAL(IS)
   If !Empty(_rFiliais)
	  _cFiltro += " AND E2.E2_FILIAL IN " + FormatIn(_rFiliais,";")
   EndIf                    

   //Considera somente titulos que entram no Fluxo de Caixa
   If _lTitFluxo
	  _cFiltro += " AND E2.E2_FLUXO = 'S'"
   EndIf             

   //Filtra somente titulos do Tipo igual
   If !Empty(_rTipTitIn)
      _cFiltro += " AND E2.E2_TIPO IN "     + FormatIn(_rTipTitIn,";")
   EndIf      

   //Filtra somente titulos do Tipo diferente
   If !Empty(_rTipTitOu)
	  _cFiltro += " AND E2.E2_TIPO NOT IN " + FormatIn(_rTipTitOu,";")
   EndIf              

   //Filtra somente naturezas iguais
   If !Empty(_rNatImpri)
	  _cFiltro += " AND E2.E2_NATUREZ IN " + FormatIn(_rNatImpri,";")
   EndIf 

   //Filtra somente naturezas diferentes
   If !Empty(_rNatNImpr)
	  _cFiltro += " AND E2.E2_NATUREZ NOT IN " + FormatIn(_rNatNImpr,";")
   EndIf                      

   _cQuery := "SELECT"  
   _cQuery += " E2.E2_FILIAL,E2.E2_PREFIXO,E2.E2_TIPO,E2.E2_NUM,E2.E2_PARCELA,E2.E2_FORNECE,E2.E2_LOJA,E2.E2_TXMOEDA,"
   _cQuery += " E2.E2_BAIXA,E2.E2_NATUREZ,E2.E2_VENCREA,E2.E2_SALDO,E2.E2_SDACRES,E2.E2_SDDECRE,A2.A2_NOME,E2.R_E_C_N_O_ RECNOSE2,"    
   _cQuery += " E2.E2_VALOR,E2.E2_DECRESC,E2_ACRESC,E2.E2_VALJUR,E2.E2_PORCJUR,E2.E2_EMISSAO,E2_VENCTO,"
   _cQuery += " (SELECT ED.ED_DESCRIC FROM " + RetSqlName("SED") + " ED WHERE ED.ED_CODIGO = E2.E2_NATUREZ AND ED.D_E_L_E_T_= ' ') ED_DESCRIC " 
   _cQuery += "FROM " + RetSqlName("SE2") + " E2 "  
   _cQuery += "JOIN " + RetSqlName("SA2") + " A2 ON A2.A2_COD = E2.E2_FORNECE AND A2.A2_LOJA = E2.E2_LOJA "
   _cQuery += "WHERE"  
   _cQuery += " E2.D_E_L_E_T_= ' '"
   _cQuery += " AND A2.D_E_L_E_T_= ' '"
   _cQuery += " AND E2.E2_VENCREA BETWEEN '" + _dDtVencIn + "' AND '" + _dDtVencFi + "'"   
   _cQuery += " AND E2.E2_EMISSAO BETWEEN '" + _dDtEmisIn + "' AND '" + _dDtEmisFi + "'" 
   _cQuery += " AND E2.E2_FORNECE BETWEEN '" + _cCodForIn + "' AND '" + _cCodForFi + "'"   
   _cQuery += " AND E2.E2_LOJA BETWEEN '"    + _cLojForIn + "' AND '" + _cLojForFi + "'" 
   _cQuery += " AND E2.E2_TIPO <> 'PA '" 
   _cQuery += _cFiltro          
	        
   //Compoe saldo do titulo For iguar a Nao, ou seja, nao calcula saldo do titulo de acordo com a data informada pelo usuario e sim pelo saldo atual
   If !_lCalSldDt
	  _cQuery += " AND E2.E2_SALDO > 0"
   EndIf 
	
   If Select(_cAliasSE2) > 0
	  (_cAliasSE2)->(DBCloseArea())
   EndIf                                                     
	
   dbUseArea( .T., "TOPCONN",TcGenQry(,,_cQuery),_cAliasSE2,.T.,.T.)
   COUNT TO nCountRec //Contabiliza o numero de registros encontrados pela query
	
   ProcRegua(nCountRec) 
	 
   DBSelectArea(_cAliasSE2)
   (_cAliasSE2)->(DBGoTop())    
	
   //Percorre todos os registros selecionados na query grupando os dados para os tipo diferentes de relatorio a gerar
   While (_cAliasSE2)->(!Eof())        
      IncProc("Efetuando o calculo do saldo dos Titulos")
	  
	  // Utilizado arrya para quando nao For aglutinar por Filial 
      nPosFilial:= aScan( _aFilial,{|x| x[1] == (_cAliasSE2)->E2_FILIAL })     
	  
	  //Caso a Filial ainda nao esteja incluida no array eh feita a sua insercao 
      If nPosFilial == 0                          
         aAdd(_aFilial,{ (_cAliasSE2)->E2_FILIAL })
      EndIf    
	            
      _nSaldoTit:= 0     
      
      //Calcula saldo a partir da data base 
      If _lCalSldDt     
	     //Para que essa funcao funcione eh necessario que antes esteja posicionado no titulo
	     #IFDEF TOP
		    If TcSrvType() != "AS/400"
			   // Posiciona SE2 ou SE1 para pegar o saldo do titulo correto
			   SE2->(DBGoTo((_cAliasSE2)->RECNOSE2))
            EndIf	
         #EndIf
	    
	     _nSaldoTit:= SaldoTit((_cAliasSE2)->E2_PREFIXO,;             			//PREFIXO DO TITULO
		      		          (_cAliasSE2)->E2_NUM,;                 			//NUMERO DO TITULO
				    		  (_cAliasSE2)->E2_PARCELA,;             			//PARCELA DO TITULO
					    	  (_cAliasSE2)->E2_TIPO,;                			//TIPO DO TITULO
				    		  (_cAliasSE2)->E2_NATUREZ,;            			//NATUREZA DO TITULO
					    	  "P",;                                  			//TIPO DA CARTEIRA A PAGAR OU RECEBER - P == PAGAR - R == RECEBER
				    		  (_cAliasSE2)->E2_FORNECE,;            			//CODIGO DO FORNECEDOR
			    			  nMoeda,; 								 			//CODIGO DA MOEDA CORRENTE 
		    				  SToD((_cAliasSE2)->E2_VENCREA),;        			//DATA DE CONVERSAO 
		    				  _dDtBase,;                            			//DATA DA BAIXA A SER CONSIDERADA (RETROATIVA) - SER For IGUAL OU MAIOR CONSIDERA A BAIXA
			    			  (_cAliasSE2)->E2_LOJA,;              				//CODIGO DA LOJA DO FORNECEDOR DO TITULO CORRENTE
				    		  (_cAliasSE2)->E2_FILIAL,;   						//FILIAL DO TITULO
				    		  If(cPaisLoc=="BRA",(_cAliasSE2)->E2_TXMOEDA,0)) //TAXA DA MOEDA   
							  
         // Subtrai decrescimo para recompor o saldo na data escolhida.
	     If Str((_cAliasSE2)->E2_VALOR,17,2) == Str(_nSaldoTit,17,2) .And. (_cAliasSE2)->E2_DECRESC > 0 .And. (_cAliasSE2)->E2_SDDECRE == 0
		    _nSaldoTit -= SE2->E2_DECRESC
	     EndIf
		 
	     // Soma Acrescimo para recompor o saldo na data escolhida.
	     If Str((_cAliasSE2)->E2_VALOR,17,2) == Str(_nSaldoTit,17,2) .And. (_cAliasSE2)->E2_ACRESC > 0 .And. (_cAliasSE2)->E2_SDACRES == 0
	        _nSaldoTit += SE2->E2_ACRESC
	     EndIf	 
				
         nJurTit := FaJuros((_cAliasSE2)->E2_VALOR,(_cAliasSE2)->E2_SALDO,SToD((_cAliasSE2)->E2_VENCTO),(_cAliasSE2)->E2_VALJUR,(_cAliasSE2)->E2_PORCJUR,;
		            nMoeda,SToD((_cAliasSE2)->E2_EMISSAO),_dDtBase,(_cAliasSE2)->E2_TXMOEDA,SToD((_cAliasSE2)->E2_BAIXA))	
				           
	     _nSaldoTit +=  nJurTit          
				              
	     //MVPAGANT == PA
	     //MV_CPNEG == NDF
         If ! ((_cAliasSE2)->E2_TIPO $ MVPAGANT+"/"+MV_CPNEG) .And. ;
		    ! (_nSaldoTit == 0 ) // nao deve olhar abatimento pois e zerado o saldo na liquidacao final do titulo

		 //Quando considerar Titulos com emissao futura, eh necessario
		 //colocar-se a database para o futuro de forma que a Somaabat()
		 //considere os titulos de abatimento
		    //If MV_PAR36 == 1
		       dOldData := dDataBase
		       dDataBase := CTOD("31/12/40")
		    //EndIf

		    _nSaldoTit -= SomaAbat((_cAliasSE2)->E2_PREFIXO,(_cAliasSE2)->E2_NUM,(_cAliasSE2)->E2_PARCELA,"P",nMoeda,SToD((_cAliasSE2)->E2_VENCREA),(_cAliasSE2)->E2_FORNECE,(_cAliasSE2)->E2_LOJA)

		    //If MV_PAR36 == 1
		       dDataBase := dOldData
		    //EndIf
	     EndIf					  							  				  
	        
	  //Nao calcula saldo a partir da data base e sim o saldo atual do titulo
	  Else     
		 _nSaldoTit:= ( (_cAliasSE2)->E2_SALDO + (_cAliasSE2)->E2_SDACRES ) - (_cAliasSE2)->E2_SDDECRE
	  EndIf
	                    
	  //Somente se houver saldo no Titulo corrente para ser considerado
	  If Abs(_nSaldoTit) > 0.0001                
		 //Funcao responsavel por armazenar os dados pela data de vencimento
		 RFIN008DD()  
			
		 //Funcao responsavel por armazenar os dados pela data de vencimento + fornecedor + Natureza
		 RFIN008DF()   
			
		 //Funcao responsavel por armazenar os dados pela natureza dos titulos
	     RFIN008DN()     
	  EndIf
		
	  DBSelectArea(_cAliasSE2)
	  (_cAliasSE2)->(DBSkip())     
		
   EndDo
                                  
   //Fecha a Area
   DBSelectArea(_cAliasSE2) 
   (_cAliasSE2)->(DBCloseArea()) 
	                 
   //Verifica a existencia de pelo menos um registro na query
   If Len(_aFilial) > 0
      //Nao Aglutina por Filial eh feita a ordenacao das Filiais 
	  If !_lAglutFil                                            
	     _aFilial:= aSort(_aFilial,,,{|x, y| x[1] < y[1] })		// Ordenar 
	     //Imprime os dados por Filial
		 For y:=1 to Len(_aFilial)    
		     If _nGerExcel <> 1 // Gera relatório impresso
		        //Funcaro responsavel por imprmir os dados do relatorio por dia de Pagamento
			    RFIN008VD(_aFilial[y,1])    
			    //Funcaro responsavel por imprmir os dados do relatorio por dia de Pagamento + Fornecedor + Natureza
			    RFIN008VF(_aFilial[y,1])      
			    //Funcao responsavel por imprimir os dados do relatorio por Natureza
			    RFIN008VN(_aFilial[y,1])
			 Else // gera relatorio em Excel
                //Funcaro responsavel por Gerar os dados do relatorio por dia de Pagamento, em Excel.
			    RFIN008YD(_aFilial[y,1])    
			    //Funcaro responsavel por Gerar os dados do relatorio por dia de Pagamento + Fornecedor + Natureza
			    RFIN008YF(_aFilial[y,1])      
			    //Funcao responsavel por  Gerar os dados do relatorio por Natureza
			    RFIN008YN(_aFilial[y,1])					
			 EndIf
		 Next y
				    
		 //Caso aglutine por Filial
	  Else 
	     If _nGerExcel <> 1 // Gera relatório impresso.
	        //Funcaro responsavel por imprmir os dados do relatorio por dia de Pagamento
	        RFIN008VD(_aFilial[Len(_aFilial),1])  
	 	    //Funcaro responsavel por imprmir os dados do relatorio por dia de Pagamento + Fornecedor + Natureza
		    RFIN008VF(_aFilial[Len(_aFilial),1])  
		    //Funcao responsavel por imprimir os dados do relatorio por Natureza
		    RFIN008VN(_aFilial[Len(_aFilial),1])
		 Else // Gerar relatório em Excel.
		    //Funcaro responsavel por gerar os dados do relatorio por dia de Pagamento, em Excel.
		    RFIN008YD(_aFilial[Len(_aFilial),1])  
		    //Funcaro responsavel por gerar os dados do relatorio por dia de Pagamento + Fornecedor + Natureza, em Excel.
		    RFIN008YF(_aFilial[Len(_aFilial),1])  
		    //Funcao responsavel por gerar os dados do relatorio por Natureza, em Excel.
		    RFIN008YN(_aFilial[Len(_aFilial),1])
		 EndIf
	  EndIf               
   EndIf
   
   If _nGerExcel == 1 // Exibe o relatório em Excel.
	  aAdd(_aDetalhePlanilha, _aDadosRDia)
      aAdd(_aDetalhePlanilha, _aDadosRTit)
      aAdd(_aDetalhePlanilha, _aDadosRNat)

      _cTitulo := "Relatório Financeiro de Demonstração do Resumo de Contas a Pagar"
	  //ITGEREXCEL(_cNomeArq,_cDiretorio,_cTitulo,_cNomePlan                     ,_aCabecalho    ,_aDetalhe        ,_lLeTabTemp ,_cAliasTab,_aCampos,_lScheduller,_lCriaPastas) 
      U_ITGEREXCEL(         ,           ,_cTitulo,"Relatorio_Resumo_Contas_a_PG_",_aCabecPlanilha,_aDetalhePlanilha,.F.         ,          ,        ,.F.         , .T.     ) 

   EndIf

End Sequence
	                          	    
FWRestArea(_aAreaGer)   

Return

/*
===============================================================================================================================
Programa--------: RFIN008QP
Autor-----------: Fabiano Dias
Data da Criacao-: 30/07/2010
Descrição-------: Função que Processa a quebra de páginas do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RFIN008QP(nLinhas,impBox,nTipBoxDiv,_cFil)   

	//Quebra de pagina
	If nLinha > nqbrPagina
				
		nlinha:= nlinha - (nSaltoLinha * nLinhas)
		
		If impBox == 0  
		        
		       //Para o tipo de relatorio resumido por dia de pagamento	
			   If nTipBoxDiv == 1	
		   	   		RFIN008B()
		   	   		//Para o tipo de relatorio por data de pagamento + Fornecedor + Natureza			
					ElseIf nTipBoxDiv == 2 
						RFIN008FB()
							ElseIf nTipBoxDiv == 3
								RFIN008NB()	    
		   	   EndIf
		   	   
		EndIf	 
		
		oPrint:EndPage()					// Finaliza a Pagina.
		oPrint:StartPage()					//Inicia uma nova Pagina					
		nPagina++
		
		RFIN008C(1,_cFil)//Chama cabecalho    
		
		nlinha+=nSaltoLinha                   
		nlinha+=nSaltoLinha  
		
		//Para o tipo de relatorio resumido por dia de pagamento	
		If nTipBoxDiv == 1	    		
			RFIN008D()       
				//Para o tipo de relatorio por data de pagamento + Fornecedor + Natureza			
				ElseIf nTipBoxDiv == 2 					
					RFIN008F() 
					//Para o tipo do relatorio por Natureza
						ElseIf nTipBoxDiv == 3						    
							RFIN008N()
		EndIf	

		nlinha+=nSaltoLinha   
		oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
		
	EndIf  
	
Return

/*
===============================================================================================================================
Programa--------: RFIN008IP
Autor-----------: Fabiano Dias
Data da Criacao-: 30/07/2010
Descrição-------: Funcao criada para impressao da pagina de parametros do relatorio
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RFIN008IP(oPrint)      

Local nAux     := 1   
Local nqtdeCar

Local _aDadosPegunte := {}
Local _nI
Local _cTexto

//Quantidade de caracteres para quebra de Linha
nqtdeCar:= 84	

oPrint:StartPage()   // Inicia uma nova página     
nLinha+= 080                                    
oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
nLinha+= 60

aAdd(_aDadosPegunte,{"01", "Aglutinar Filial ?"             , "MV_PAR01"})       
aAdd(_aDadosPegunte,{"02", "Aglutinar Titulo ?"             , "MV_PAR02"})           
aAdd(_aDadosPegunte,{"03", "Saldo Titulo prox. parametro ?" , "MV_PAR03"})
aAdd(_aDadosPegunte,{"04", "Data Base ? "                   , "MV_PAR04"})           
aAdd(_aDadosPegunte,{"05", "Somente Titulos p/ Fluxo ?"     , "MV_PAR05"})
aAdd(_aDadosPegunte,{"06", "Filial(is) ? "                  , "MV_PAR06"})
aAdd(_aDadosPegunte,{"07", "Emissao de ? "                  , "MV_PAR07"})  
aAdd(_aDadosPegunte,{"08", "Emissao ate ?"                  , "MV_PAR08"})  
aAdd(_aDadosPegunte,{"09", "Vencimento de ?"                , "MV_PAR09"})       
aAdd(_aDadosPegunte,{"10", "Vencimento ate ?"               , "MV_PAR10"})           
aAdd(_aDadosPegunte,{"11", "Imprimir Tipos ? "              , "MV_PAR11"})
aAdd(_aDadosPegunte,{"12", "Nao Imprimir Tipos ?"           , "MV_PAR12"})           
aAdd(_aDadosPegunte,{"13", "Fornecedor de ?"                , "MV_PAR13"})          
aAdd(_aDadosPegunte,{"14", "Loja de ?"                      , "MV_PAR14"})
aAdd(_aDadosPegunte,{"15", "Fornecedor ate ?"               , "MV_PAR15"})
aAdd(_aDadosPegunte,{"16", "Loja ate ?"                     , "MV_PAR16"})  
aAdd(_aDadosPegunte,{"17", "Imprimir Naturezas ? "          , "MV_PAR17"})  
aAdd(_aDadosPegunte,{"18", "Nao Imprimir Naturezas ?"       , "MV_PAR18"})

For _nI := 1 To Len(_aDadosPegunte)          
	nAux:= 1      
	
	oPrint:Say (nLinha,nColInic + 10,"Pergunta " + _aDadosPegunte[_nI,1] + ':' +  _aDadosPegunte[_nI,2] , oFont14Prb)    
		
	If _aDadosPegunte[_nI,3] == "MV_PAR01"
	   If MV_PAR01 ==  1
	      _cTexto := "Sim"
	   ElseIf MV_PAR01 == 2
	      _cTexto := "Não"
	   Else
	      _cTexto := ""
	   EndIf
	   oPrint:Say (nLinha,1200,_cTexto,oFont14Prb)  
	
	ElseIf _aDadosPegunte[_nI,3] == "MV_PAR02"
	   If MV_PAR02 ==  1
	      _cTexto := "Sim"
	   ElseIf MV_PAR02 == 2
	      _cTexto := "Não"
	   Else
	      _cTexto := ""
	   EndIf
	   oPrint:Say (nLinha,1200,_cTexto,oFont14Prb)     	   
	
	ElseIf _aDadosPegunte[_nI,3] == "MV_PAR03"
	   If MV_PAR03 ==  1
	      _cTexto := "Sim"
	   ElseIf MV_PAR03 == 2
	      _cTexto := "Não"
	   Else
	      _cTexto := ""
	   EndIf
	   oPrint:Say (nLinha,1200,_cTexto,oFont14Prb)  	   
    
    ElseIf _aDadosPegunte[_nI,3] == "MV_PAR05"
	   If MV_PAR05 ==  1
	      _cTexto := "Sim"
	   ElseIf MV_PAR05 == 2
	      _cTexto := "Não"
	   Else
	      _cTexto := ""
	   EndIf
	   oPrint:Say (nLinha,1200,_cTexto,oFont14Prb)  
	   
    Else
       _cTexto := &(_aDadosPegunte[_nI,3])
       If ValType(_cTexto) == "D"
          _cTexto := DToC(_cTexto)
       EndIf   
       oPrint:Say (nLinha,1200,_cTexto,oFont14Prb)  		
    EndIf	
	    
	nLinha+= 60
Next
	  
nLinha+= 60
oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	
oPrint:EndPage()     // Finaliza a página

Return 

/*
===============================================================================================================================
Programa--------: RFIN008DD
Autor-----------: Fabiano Dias
Data da Criacao-: 30/07/2010
Descrição-------: Funcao que consulta e orgaiza os dados por dia
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RFIN008DD()

Local nPosDia   := 0                 
Local _cChaveFil:= ""     
Local _nSldTit  := 0
         
//Aglutina por Filial
If _lAglutFil        
        
    _cChaveFil:= "(_cAliasSE2)->E2_VENCREA"         
        
//Nao aglutina por Filial
Else    

	_cChaveFil:= "(_cAliasSE2)->E2_FILIAL + (_cAliasSE2)->E2_VENCREA" 

EndIf

If (_cAliasSE2)->E2_TIPO == 'NDF'     

	_nSldTit := _nSaldoTit * -1    
	
Else 
            
    _nSldTit := _nSaldoTit
			
EndIf
				
nPosDia := aScan( _aDiasVenc,{|x| x[6] == &(_cChaveFil)})   
		      
//Insere na data correta o saldo do titulo
If nPosDia > 0
						    
	_aDiasVenc[nPosDia,3]+= _nSldTit 
						    
Else
						    	
	aAdd(_aDiasVenc,{ (_cAliasSE2)->E2_VENCREA,(_cAliasSE2)->E2_TIPO,_nSldTit,1,'A',&(_cChaveFil)} ) 
	
EndIf		

Return

/*
===============================================================================================================================
Programa--------: RFIN008VD
Autor-----------: Fabiano Dias
Data da Criacao-: 30/07/2010
Descrição-------: Funcao que imprime o resumo do contas a pgar agrupando os dados por dia
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RFIN008VD(_cFil)

Local _nTotDia    := 0   
Local _cNomeFil   := ""
Local x				:= 0

If Len(_aDiasVenc) > 0
	
		//Monta primeiro relatorio resumido por Contas a pagar por dia de vencimento e colocar as NDF sempre em segundo lugar 
	    //Aglutina por Filial
		If _lAglutFil  
	    	//_aDiasVenc:= aSort(_aDiasVenc,,,{|x, y| x[1]+x[5] < y[1]+y[5]})		// Ordenar     
	    	_aDiasVenc:= aSort(_aDiasVenc,,,{|x, y| x[1] < y[1]})		// Ordenar     
	    	    Else
	    			//_aDiasVenc:= aSort(_aDiasVenc,,,{|x, y| x[6]+x[5] < y[6]+y[5]})		// Ordenar
	    			_aDiasVenc:= aSort(_aDiasVenc,,,{|x, y| x[6] < y[6]})		// Ordenar
	    EndIf
	    
        oPrint:EndPage()					//Finaliza a Pagina	
	    oPrint:StartPage()					//Inicia uma nova Pagina
   	    nPagina++

	    If !_lAglutFil .Or. Len(_aFilial) == 1     
	       
	    	_cNomeFil:= FWFilialName(,_cFil)
			RFIN008C(1,_cFil + '/' + _cNomeFil)
			
				Else
				    
					_cNomeFil:='Aglutinado por mais de uma Filial'
					RFIN008C(1,_cNomeFil)	             
			
		EndIf
		nlinha+=nSaltoLinha                   
		nlinha+=nSaltoLinha   
		RFIN008D()        
	    	    
	    For x:=1 to Len(_aDiasVenc)
	    
	    	If !_lAglutFil

			   If _cFil <> SubStr(_aDiasVenc[x,6],1,2)			
					Loop			   
			   EndIf
	    		
	    	EndIf
	        
	        nlinha+=nSaltoLinha  
	        oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	        RFIN008QP(1,0,1,_cNomeFil) 
	    	RFIN008P(_aDiasVenc[x,1],_aDiasVenc[x,3] * _aDiasVenc[x,4])
	    	
	    	_nTotDia+= _aDiasVenc[x,3] * _aDiasVenc[x,4] 
	    
	    Next x  
	    
	    nlinha+=nSaltoLinha  
	    oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	    RFIN008QP(0,0,1,_cNomeFil)     
	    nlinha+=nSaltoLinha  
	    oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	    RFIN008QP(0,0,1,_cNomeFil)  
	    RFIN008T('TOTAL',_nTotDia) 
	    
	    RFIN008B()
    
    EndIf

Return

/*
===============================================================================================================================
Programa--------: RFIN008DF
Autor-----------: Fabiano Dias
Data da Criacao-: 30/07/2010
Descrição-------: Funcao que imprime dados de contas a pgar agrupando os dados por dia, tipo de titulos, fornecedor e natureza
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RFIN008DF()

Local nPosForn  := 0               
Local _cChaveFil := ""
         
//Aglutina por Filial
If _lAglutFil   

	//Alutina por Titulo
	If !_lAglutTit      
        
	    //_cChaveFil:= "(_cAliasSE2)->E2_VENCREA + (_cAliasSE2)->E2_FORNECE + (_cAliasSE2)->E2_LOJA + (_cAliasSE2)->E2_NATUREZ + (_cAliasSE2)->E2_NUM + (_cAliasSE2)->E2_PARCELA"    
	    _cChaveFil:= "(_cAliasSE2)->E2_VENCREA + (_cAliasSE2)->E2_FORNECE + (_cAliasSE2)->E2_NATUREZ + (_cAliasSE2)->E2_NUM + (_cAliasSE2)->E2_PARCELA"    
	    
	    	Else 
	    	
	    		//_cChaveFil:= "(_cAliasSE2)->E2_VENCREA + (_cAliasSE2)->E2_FORNECE + (_cAliasSE2)->E2_LOJA + (_cAliasSE2)->E2_NATUREZ"       
	    		_cChaveFil:= "(_cAliasSE2)->E2_VENCREA + (_cAliasSE2)->E2_FORNECE + (_cAliasSE2)->E2_NATUREZ"
	    
	EndIf    
        
	//Nao aglutina por Filial
	Else    
	
	//Alutina por Titulo
	If !_lAglutTit      
        
	    //_cChaveFil:= "(_cAliasSE2)->E2_FILIAL + (_cAliasSE2)->E2_VENCREA + (_cAliasSE2)->E2_FORNECE + (_cAliasSE2)->E2_LOJA + (_cAliasSE2)->E2_NATUREZ + (_cAliasSE2)->E2_NUM + (_cAliasSE2)->E2_PARCELA" 
	    _cChaveFil:= "(_cAliasSE2)->E2_FILIAL + (_cAliasSE2)->E2_VENCREA + (_cAliasSE2)->E2_FORNECE + (_cAliasSE2)->E2_NATUREZ + (_cAliasSE2)->E2_NUM + (_cAliasSE2)->E2_PARCELA" 
	    
	    	Else 
	    	
	    		//_cChaveFil:= "(_cAliasSE2)->E2_FILIAL + (_cAliasSE2)->E2_VENCREA + (_cAliasSE2)->E2_FORNECE + (_cAliasSE2)->E2_LOJA + (_cAliasSE2)->E2_NATUREZ" 
	    		_cChaveFil:= "(_cAliasSE2)->E2_FILIAL + (_cAliasSE2)->E2_VENCREA + (_cAliasSE2)->E2_FORNECE + (_cAliasSE2)->E2_NATUREZ" 
	    
	EndIf             
	

EndIf

If (_cAliasSE2)->E2_TIPO <> 'NDF' 
	
		nPosForn := aScan( _aForn,{|x| x[6] == &(_cChaveFil) .And. x[2] <> 'NDF' })   
		      
		//Insere na data correta o saldo do titulo
		If nPosForn > 0
		    
		    _aForn[nPosForn,3]+= _nSaldoTit 
		                                  
		    //Para caso o titulo do Tipo PR esteja aglutinado com outro tipo de titulo para que nao seja impresso (previsao)
		    //na impressao este titulo eh setado com vazio
		    If _aForn[nPosForn,2] == "PR " .And. (_cAliasSE2)->E2_TIPO <> "PR "
		    
		    	_aForn[nPosForn,2]:= "   "  
		    
		    EndIf
		    
		    	Else
		    	                     
		    		//Array que armazena - Vencimento Real, Tipo do Titulo, Saldo e fator de conversao para indicar no caso dos titulo NDF um valor negativo
		    		aAdd(_aForn,{ (_cAliasSE2)->E2_VENCREA,(_cAliasSE2)->E2_TIPO,_nSaldoTit,1,'A',&(_cChaveFil),;
		    		(_cAliasSE2)->E2_FORNECE,(_cAliasSE2)->E2_LOJA,(_cAliasSE2)->A2_NOME,(_cAliasSE2)->E2_NATUREZ,(_cAliasSE2)->ED_DESCRIC } )   
			
		EndIf    
		       
			//Caso o titulo seja do tipo NDF devera ser cria um registro somente para este tipo
			Else
			
				nPosForn := aScan( _aForn,{|x| x[6] == &(_cChaveFil) .And. x[2] == 'NDF' })   
		      
				//Insere na data correta o saldo do titulo
				If nPosForn > 0
						    
					_aForn[nPosForn,3]+= _nSaldoTit 
						    
						Else
						    	
							aAdd(_aForn,{ (_cAliasSE2)->E2_VENCREA,(_cAliasSE2)->E2_TIPO,_nSaldoTit,-1,'Z',&(_cChaveFil),;
							(_cAliasSE2)->E2_FORNECE,(_cAliasSE2)->E2_LOJA,(_cAliasSE2)->A2_NOME,(_cAliasSE2)->E2_NATUREZ,(_cAliasSE2)->ED_DESCRIC } )  
	
				EndIf
	EndIf			

Return

/*
===============================================================================================================================
Programa--------: RFIN008VF
Autor-----------: Fabiano Dias
Data da Criacao-: 30/07/2010
Descrição-------: Funcao que imprime o resumo do contas a pgar agrupando os dados por dia, tipo de titulos, fornecedor e nat
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RFIN008VF(_cFil)

Local _nTotDia    := 0   
Local _cNomeFil   := ""
Local _aDia       := {} 
Local nPosDia     := 0
Local nTotalDia   := 0
Local x				:= 0

If Len(_aForn) > 0
	

		_aForn:= aSort( _aForn,,,{|x, y| x[6]+x[5] < y[6]+y[5] })		// Ordena os Dados    

	    
        oPrint:EndPage()					//Finaliza a Pagina	
	    oPrint:StartPage()					//Inicia uma nova Pagina
	    nPagina++							//Variavel de controle do numero da Pagina
	    
	    If !_lAglutFil .Or. Len(_aFilial) == 1     
	       
	    	_cNomeFil:= FWFilialName(,_cFil)
			RFIN008C(1,_cFil + '/' + _cNomeFil)
			
				Else
				    
					_cNomeFil:='Aglutinado por mais de uma Filial'
					RFIN008C(1,_cNomeFil)	             
			
		EndIf   
		
		nlinha+=nSaltoLinha                   
		nlinha+=nSaltoLinha   
		RFIN008F()        
	    	    
	    For x:=1 to Len(_aForn)
	    
	    	If !_lAglutFil

			   If _cFil <> SubStr(_aForn[x,6],1,2)			
					Loop			   
			   EndIf
	    		
	    	EndIf                   
	    	
	    	nPosDia := aScan( _aDia,{|z| z[1] ==  _aForn[x,1] })  
	    	 
	    	//Para criar a linha somente com o dia de pagamento uma unica vez
	    	If nPosDia == 0           
	    	
	    		aAdd(_aDia,{_aForn[x,1]})    
		    	
		    	//Para saltar uma linha da segunda data em diante, para melhorar a visibilidade
		    	If Len(_aDia) > 1
		    		//Imprime Totalizador por Dia 
		    		nlinha+=nSaltoLinha  
		        	oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
		        	RFIN008QP(0,0,2,_cNomeFil) 
		        	RFIN008T("TOTAL DO DIA: " + DToC(SToD(_aDia[Len(_aDia)-1,1])),nTotalDia)
		    		
	    	    	nlinha+=nSaltoLinha
	    	    	oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	    		EndIf
	    		    		
	    	 	nlinha+=nSaltoLinha  
		        oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
		        RFIN008QP(0,0,2,_cNomeFil) 
	        
	  			oPrint:Say (nlinha + nAjuAltLi1,nColInic	 + 20 ,DToC(SToD(_aForn[x,1])),oFont12b)   
	  			
	  			//seta totalizador por dia
	  			nTotalDia:= _aForn[x,3] * _aForn[x,4]
	  			
	  				Else
	  				
	  					//Incrementa Totalizador Por dia
	  					nTotalDia+= _aForn[x,3] * _aForn[x,4]
	    	
	    	EndIf         
	        
	        nlinha+=nSaltoLinha  
	        oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	        RFIN008QP(1,0,2,_cNomeFil) 
	        	    	           
			RFIN008FP(AllTrim(_aForn[x,7])+'-'+ AllTrim(_aForn[x,9]) + IIf(_aForn[x,2] == 'PR ','(PREVISAO)',''),;
	    	           AllTrim(_aForn[x,10]) +'-'+ AllTrim(_aForn[x,11]), _aForn[x,3] * _aForn[x,4])	    	           
	    	
	    	_nTotDia+= _aForn[x,3] * _aForn[x,4] 
	    
	    Next x  
	                  
	    nlinha+=nSaltoLinha  
		oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
		RFIN008QP(0,0,2,_cNomeFil) 
		If Len(_aDia) > 1
			RFIN008T("TOTAL DO DIA: " + DToC(SToD(_aDia[Len(_aDia),1])),nTotalDia)	
		Endif		    		
	    
	    nlinha+=nSaltoLinha  
	    oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	    RFIN008QP(0,0,2,_cNomeFil)     
	    nlinha+=nSaltoLinha  
	    oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	    RFIN008QP(0,0,2,_cNomeFil)  
	    RFIN008T('TOTAL GERAL',_nTotDia) 
	    
	    RFIN008FB()
    
    EndIf

Return

/*
===============================================================================================================================
Programa--------: RFIN008DN
Autor-----------: Fabiano Dias
Data da Criacao-: 30/07/2010
Descrição-------: Funcao que imprime Dados do contas a pagar agrupando por natureza
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RFIN008DN()

Local nPosNat   := 0                 
Local _cChaveFil:= ""    
Local _nSldTit  := 0
         
//Aglutina por Filial
If _lAglutFil        
        
    _cChaveFil:= "(_cAliasSE2)->E2_NATUREZ"         
        
	//Nao aglutina por Filial
	Else    
	
		_cChaveFil:= "(_cAliasSE2)->E2_FILIAL + (_cAliasSE2)->E2_NATUREZ" 

EndIf

If (_cAliasSE2)->E2_TIPO == 'NDF'   

	_nSldTit:= _nSaldoTit * -1 
	
		Else
		
			_nSldTit:= _nSaldoTit  

EndIf
	
			
nPosNat := aScan( _aNatureza,{|x| x[7] == &(_cChaveFil)})   
		      
//Insere na data correta o saldo do titulo
If nPosNat > 0
						    
	_aNatureza[nPosNat,4]+= _nSldTit 
						    
	Else
						    	
		aAdd(_aNatureza,{ (_cAliasSE2)->E2_NATUREZ,(_cAliasSE2)->ED_DESCRIC,(_cAliasSE2)->E2_TIPO,_nSldTit,1,'A',&(_cChaveFil)} ) 
	
EndIf

Return

/*
===============================================================================================================================
Programa--------: RFIN008VN
Autor-----------: Fabiano Dias
Data da Criacao-: 30/07/2010
Descrição-------: Funcao que imprime o resumo do contas a pagar agrupando os dados por natureza
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RFIN008VN(_cFil)

Local _nTotNat    := 0   
Local _cNomeFil   := ""
Local x				:= 0

If Len(_aNatureza) > 0
	
		//Monta primeiro relatorio resumido por Contas a pagar por dia de vencimento e colocar as NDF sempre em segundo lugar 
	    //Aglutina por Filial
	    //_aNatureza:= aSort(_aNatureza,,,{|x, y| x[7]+x[6] < y[7]+y[6] })		// Ordenar     
	    _aNatureza:= aSort(_aNatureza,,,{|x, y| x[7] < y[7]})		// Ordenar     
	    
        oPrint:EndPage()														//Finaliza a Pagina	
	    oPrint:StartPage()														//Inicia uma nova Pagina
	    nPagina++																//Variavel de controle do numero da Pagina
	    
	    If !_lAglutFil .Or. Len(_aFilial) == 1     
	       
	    	_cNomeFil:= FWFilialName(,_cFil)
			RFIN008C(1,_cFil + '/' + _cNomeFil)
			
				Else
				    
					_cNomeFil:='Aglutinado por mais de uma Filial'
					RFIN008C(1,_cNomeFil)	             
			
		EndIf                  
		
		nlinha+=nSaltoLinha                   
		nlinha+=nSaltoLinha   
		RFIN008N()        
	    	    
	    For x:=1 to Len(_aNatureza)
	    
	    	If !_lAglutFil

			   If _cFil <> SubStr(_aNatureza[x,7],1,2)			
					Loop			   
			   EndIf
	    		
	    	EndIf
	        
	        nlinha+=nSaltoLinha  
	        oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	        RFIN008QP(1,0,3,_cNomeFil) 
	    	RFIN008NP(AllTrim(_aNatureza[x,1]) + '-' + AllTrim(_aNatureza[x,2]),_aNatureza[x,4] * _aNatureza[x,5])
	    	
	    	_nTotNat+= _aNatureza[x,4] * _aNatureza[x,5] 
	    
	    Next x  
	    
	    nlinha+=nSaltoLinha  
	    oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	    RFIN008QP(0,0,3,_cNomeFil)     
	    nlinha+=nSaltoLinha  
	    oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	    RFIN008QP(0,0,3,_cNomeFil)  
	    RFIN008T('TOTAL',_nTotNat) 
	    
	    RFIN008NB()
	    
	    RFIN008AS(_cNomeFil)
    
    EndIf

Return

/*
===============================================================================================================================
Programa--------: RFIN008AS
Autor-----------: Fabiano Dias
Data da Criacao-: 30/07/2010
Descrição-------: Funcao que imprime os campos para assinaturas no relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RFIN008AS(_cFil)  

Local cNomeUsr   := ""
Local cDepto     := ""

If Type('__cUserId') == 'C'
	cNomeUsr := FWSFAllUsers({__cUserID},{"USR_NOME"})[1][3]
	cDepto   := FWSFAllUsers({__cUserID},{"USR_DEPTO"})[1][3]
EndIf

If !Empty(cNomeUsr)

	RFIN008Q2(nlinha + (nSaltoLinha * 6),_cFil)
	nlinha+=nSaltoLinha  
	nlinha+=nSaltoLinha
	nlinha+=nSaltoLinha
	nlinha+=nSaltoLinha
	        
	oPrint:Say (nlinha,nColFinal / 2,'_____________________________________________________'    ,oFont12b,nColFinal,,,2)
	nlinha+=nSaltoLinha
	oPrint:Say (nlinha,nColFinal / 2 ,Upper(AllTrim(cNomeUsr))                         ,oFont12b,nColFinal,,,2)
	nlinha+=nSaltoLinha
	oPrint:Say (nlinha,nColFinal / 2 ,Upper(AllTrim(cDepto))                        ,oFont12b,nColFinal,,,2)

EndIf                  

Return     

/*
===============================================================================================================================
Programa--------: RFIN008Q2
Autor-----------: Fabiano Dias
Data da Criacao-: 30/07/2010
Descrição-------: Funcao que Processa as quebras de paginas
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function RFIN008Q2(numero,_cFil)
      
	//quando acaba de imprimir os produtos e se chega no final da pagina     
	//final da pagina 3300
	If nLinha > numero                    
		//Imprime box 
		oPrint:EndPage()	// Finaliza a Pagina.
		oPrint:StartPage()	// Inicia uma nova pagina                  
		nPagina++
		
		RFIN008C(1,_cFil)//Chama cabecalho    
		
		nlinha+=nSaltoLinha                   
		nlinha+=nSaltoLinha  
	EndIf

Return

/*
===============================================================================================================================
Programa--------: RFIN008YD
Autor-----------: Julio de Paula Paz
Data da Criacao-: 25/04/2019
Descrição-------: Gera para o relatório em Excel os dados do resumo do contas a pagar agrupando os dados por dia.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RFIN008YD(_cFil)

Local _cNomeFil   := ""
Local _cCodFil    := ""
Local x				:= 0

Begin Sequence
   
   If Len(_aDiasVenc) > 0
	  // Monta primeiro relatorio resumido por Contas a pagar por dia de vencimento e colocar as NDF sempre em segundo lugar 
	  // Aglutina por Filial
	  If _lAglutFil  
	     _aDiasVenc:= aSort(_aDiasVenc,,,{|x, y| x[1] < y[1]})		// Ordenar     
	  Else
	  	 _aDiasVenc:= aSort(_aDiasVenc,,,{|x, y| x[6] < y[6]})		// Ordenar
	  EndIf

      If !_lAglutFil .Or. Len(_aFilial) == 1     
	     _cNomeFil:= FWFilialName(,_cFil)
		 _cCodFil := _cFil
	  Else
		 _cNomeFil:='Aglutinado por mais de uma Filial'
		 _cCodFil := ""
	  EndIf

	  For x:=1 to Len(_aDiasVenc)
    	  If ! _lAglutFil
			 If _cFil <> SubStr(_aDiasVenc[x,6],1,2)			
				Loop			   
			 EndIf
	      EndIf
	      //               {"FILIAL","NOME FILIAL","DIA"                       ,"VALOR"}  
          aAdd(_aDadosRDia,{_cCodFil, _cNomeFil   , DToC(SToD(_aDiasVenc[x,1])),_aDiasVenc[x,3] * _aDiasVenc[x,4]})
   
	  Next x  

   EndIf

End Sequence

Return

/*
===============================================================================================================================
Programa--------: RFIN008YF
Autor-----------: Julio de Paula Paz
Data da Criacao-: 25/04/2019
Descrição-------: Gera para o relatório em Excel os dados do resumo do contas a pagar agrupados por dia, tipo de titulos, 
                  fornecedor e nat.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RFIN008YF(_cFil)

Local _cNomeFil   := ""
Local _aDia       := {} 
Local nPosDia     := 0
Local _cCodFil    := ""
Local x				:= 0
Begin Sequence
     If Len(_aForn) > 0
	  _aForn:= aSort( _aForn,,,{|x, y| x[6]+x[5] < y[6]+y[5] })		// Ordena os Dados    
	    
	  If ! _lAglutFil .Or. Len(_aFilial) == 1     
    	 _cNomeFil:= FWFilialName(,_cFil)
		 _cCodFil    := _cFil
	  Else
	     _cCodFil    := ""
		 _cNomeFil:='Aglutinado por mais de uma Filial'
	  EndIf   
		
	  For x:=1 to Len(_aForn)
	      If !_lAglutFil
		     If _cFil <> SubStr(_aForn[x,6],1,2)			
				Loop			   
			 EndIf
	      EndIf                   
	    	
	      nPosDia := aScan( _aDia,{|z| z[1] ==  _aForn[x,1] })  
	    	 
	      //Para criar a linha somente com o dia de pagamento uma unica vez
	      If nPosDia == 0           
	    	 aAdd(_aDia,{_aForn[x,1]})    
	      EndIf         
          //               {"DIA"                  ,"FILIAL", "NOME FILIAL","FORNECEDOR"         ,"NOME FORNECEDOR"                                                ,"NATUREZA"             , "DESC.NATUREZA"      , "VALOR"}
          aAdd(_aDadosRTit,{DToC(SToD(_aForn[x,1])),_cCodFil, _cNomeFil    , AllTrim(_aForn[x,7]), AllTrim(_aForn[x,9]) + IIf(_aForn[x,2] == 'PR ','(PREVISAO)',''), AllTrim(_aForn[x,10]) ,AllTrim(_aForn[x,11]) , _aForn[x,3] * _aForn[x,4]})

      Next x  

   EndIf

End Sequence

Return

/*
===============================================================================================================================
Programa--------: RFIN008YN
Autor-----------: Julio de Paula Paz
Data da Criacao-: 25/04/2019
Descrição-------: Funcao que Gera em Excel o resumo do contas a pagar agrupando os dados por natureza.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RFIN008YN(_cFil)

Local _cNomeFil   := ""
Local _cCodFil    := ""
Local x				:= 0
Begin Sequence
   If Len(_aNatureza) > 0
	  // Monta primeiro relatorio resumido por Contas a pagar por dia de vencimento e colocar as NDF sempre em segundo lugar 
	  // Aglutina por Filial
	  _aNatureza:= aSort(_aNatureza,,,{|x, y| x[7] < y[7]})		// Ordenar     
	    
      If !_lAglutFil .Or. Len(_aFilial) == 1     
    	 _cNomeFil:= FWFilialName(,_cFil)
		 _cCodFil := _cFil
	  Else
  		 _cNomeFil:='Aglutinado por mais de uma Filial'
		 _cCodFil := ""  
	  EndIf                  
		
      For x:=1 to Len(_aNatureza)
	      If !_lAglutFil
		     If _cFil <> SubStr(_aNatureza[x,7],1,2)			
				Loop			   
			 EndIf
    	  EndIf
    	  //               {"FILIAL","NOME FILIAL","NATUREZA"               ,"DESC.NATUREZA"          ,"VALOR"}
    	  aAdd(_aDadosRNat,{_cCodFil, _cNomeFil   , AllTrim(_aNatureza[x,1]), AllTrim(_aNatureza[x,2]),_aNatureza[x,4] * _aNatureza[x,5]})
    	  
      Next x  
   EndIf

End Sequence

Return
