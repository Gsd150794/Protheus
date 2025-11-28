/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |30/08/2021| Chamado 37601. Trazer o conteúdo do campo RA_NSOCIAL, quando preenchido no lugar do RA_NOME.
Alex Wallauer |27/09/2021| Chamado 37852. Correcao do error.log relatado.
Alex Wallauer |11/06/2024| Chamado 47228. Vanderlei. Colocada uma coluna com o nome da Filial.
===============================================================================================================================
*/

#Include "report.ch"  
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGPE017
Autor-------------: Alex Wallauer
Data da Criacao---: 10/08/2018
Descricao---------: Relacao de Aniversariantes do Mes  - CHAMADO: 25726
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================*/
User Function RGPE017()
Local	oReport   
Local	aArea 	:= FWGetArea()
Private	_cAliasSRA	:= "SRA"				// Alias do arquivo principal (Base)
Private cPerg	:= "GP260R"
Private aOrd    := {OemToAnsi("Data Nascimento"),OemToAnsi("Matricula"),OemToAnsi("Centro de Custo"),OemToAnsi("Nome")}	
Private cTitulo	:= OemToAnsi(" RELACAO DE ANIVERSARIANTES NO MES ")
Private cAliasQry:=""
		
	// Verifica as perguntas selecionadas      
	Pergunte(cPerg,.F.) 	
    oReport := ReportDef()
    oReport:PrintDialog()     

FWRestArea( aArea )

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Alex Wallauer
Data da Criacao---: 10/08/2018
Descricao---------: Relacao de Aniversariantes do Mes
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef() 
Local oReport 
Local oSection1 
	
	// Criacao dos componentes de impressao                                    
	DEFINE REPORT oReport NAME "RGPE017" TITLE cTitulo PARAMETER cPerg ACTION {|oReport| R260Imp(oReport)} DESCRIPTION OemtoAnsi("Este programa emite Relacao de Aniversariantes do Mes.") TOTAL IN COLUMN	 
	//"Este programa emite Relacao de Aniversariantes do Mes."
	
		DEFINE Section oSection1 OF oReport TITLE OemToAnsi("Funcionarios") TABLES "SRA" TOTAL IN COLUMN ORDERS aOrd  //Funcionarios
	
			DEFINE CELL NAME "RA_FILIAL" 	OF oSection1 SIZE 30 BLOCK {|| (cAliasQry)->RA_FILIAL+ " - " + AllTrim(FWFilialName(cEmpAnt,(cAliasQry)->RA_FILIAL)) }
//			DEFINE CELL NAME "RA_CHAPA"	 	OF oSection1 ALIAS _cAliasSRA
			DEFINE CELL NAME "RA_NASC"		OF oSection1 ALIAS _cAliasSRA
			DEFINE CELL NAME "RA_MAT" 	 	OF oSection1 ALIAS _cAliasSRA
			DEFINE CELL NAME "RA_NOME" 	 	OF oSection1 ALIAS _cAliasSRA BLOCK {|| If(!Empty((cAliasQry)->RA_NSOCIAL),(cAliasQry)->RA_NSOCIAL,(cAliasQry)->RA_NOME)	}
  			DEFINE CELL NAME "CTT_DESC01" 	OF oSection1 ALIAS "CTT"  TITLE "Centro de Csuto"
  			DEFINE CELL NAME "ZAK_DESCRI" 	OF oSection1 ALIAS "ZAK"  TITLE "Setor"
			DEFINE CELL NAME "DNASCIM"		OF oSection1 TITLE OemToAnsi("Aniversario") PICTURE "99/99" ;	//	"Aniversario"
					BLOCK {||PadR(SubStr(oSection1:Cell("RA_NASC"):GetText(),1,5),14)}
			DEFINE CELL NAME "RA_ESTCIVI"	OF oSection1 ALIAS _cAliasSRA SIZE 15	;	//	"Estado Civil   "
					BLOCK{||Tabela("33",RA_ESTCIVI)}
	
	Return(oReport)

/*
===============================================================================================================================
Programa----------: R260Imp
Autor-------------: Alex Wallauer
Data da Criacao---: 10/08/2018
Descricao---------: Relacao de Aniversariantes do Mes
Parametros--------: oReport
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function R260Imp(oReport)
Local oSection  := oReport:Section(1)
Local cSitQuery	:= ""
Local cCatQuery	:= ""  
Local cArqNtx	:= ""
Local nReg		:= 0	
Local nOrdem	:= oSection:GetOrder()

// Variaveis utilizadas para parametros                         
// MV_PAR01        //  Filial                                   
// MV_PAR02        //  Centro de Custo                          
// MV_PAR03        //  Matricula                                
// MV_PAR04        //  Nome                                     
// MV_PAR05        //  Chapa                                    
// MV_PAR06        //  Data de Nascimento                       
// MV_PAR07        //  Mes De                                   
// MV_PAR08        //  Mes Ate                                  
// MV_PAR09        //  Situacoes                                
// MV_PAR10        //  Categorias                               
// MV_PAR11        //  Imprime Salario                          
// MV_PAR12        //  Imprime Ano de Nascimento                
// MV_PAR13        //  IMprime Estado Civil                     
// MV_PAR14        //  Salta Pagina por Filial                  

//Local aCampos,cArqTrb
Local cSituacao  := MV_PAR09
Local cCategoria := MV_PAR10
//Local lImpSal    := If( MV_PAR11 == 1 , .T. , .F. )
Local lAnoNas    := If( MV_PAR12 == 1 , .T. , .F. )
Local lImpEst    := If( MV_PAR13 == 1 , .T. , .F. )
Local lSalta     := If( MV_PAR14 == 1 , .T. , .F. )
Local cFilSRACTT := "%" + FWJoinFilial("SRA", "CTT") + "%"
Local cFilSRAZAK := "%" + FWJoinFilial("SRA", "ZAK") + "%"
Local cOrdem     := ""

Private cAcessaSRA	:= &( " { || " + ChkRH( "GPER260" , "SRA" , "2" ) + " } " )
Private nMesDe     := MV_PAR07
Private nMesAte    := MV_PAR08	
	
	SET CENTURY ON
	
//	If nOrdem # 4
//		oSection:Cell("RA_CHAPA"):Disable()
//	EndIf
	
//	If !lImpSal
//		oSection:Cell("RA_SALARIO"):Disable()
//	EndIf
	
	If !lImpEst
		oSection:Cell("RA_ESTCIVI"):Disable()
	EndIf	
		
	If lAnoNas
		oSection:Cell("DNASCIM"):Disable()
	Else
		oSection:Cell("RA_NASC"):Disable()
	EndIf
	
	If oReport:Cancel()
		Return
	EndIf               
	
	If lSalta
		//-- Quebrar por Filial
		DEFINE BREAK oBreakFil OF oSection WHEN oSection:Cell("RA_FILIAL") PAGE BREAK		
	EndIf
	
	//-- Condicao de impressao do Funcionario
	oSection:SetLineCondition({|| fGP260Cond(cAliasQry) }) 
	

	cAliasQry := GetNextAlias()

	//-- Modifica variaveis para a Query 
	cSitQuery := ""
	For nReg:=1 to Len(cSituacao)
		cSitQuery += "'"+Subs(cSituacao,nReg,1)+"'"
		If ( nReg+1 ) <= Len(cSituacao)
			cSitQuery += "," 
		EndIf
	Next nReg        
	cSitQuery := "%" + cSitQuery + "%"
	
	cCatQuery := ""
	For nReg:=1 to Len(cCategoria)
		cCatQuery += "'"+Subs(cCategoria,nReg,1)+"'"
		If ( nReg+1 ) <= Len(cCategoria)
			cCatQuery += "," 
		EndIf
	Next nReg        
	cCatQuery := "%" + cCatQuery + "%"
                   
	// Transforma parametros do tipo Range em expressao ADVPL para ser utilizada no filtro
	MakeSqlExpr(cPerg)//Os conteudos paramentros tem que estar seprado com ; 
		
	BEGIN REPORT QUERY oSection

		If nOrdem == 1
			If lAnoNas
				cOrdem := "%SRA.RA_FILIAL,SRA.RA_NASC%"
			Else
				cOrdem := "%SRA.RA_FILIAL,SUBSTRING( SRA.RA_NASC, 5, 4)%"
			EndIf
		ElseIf nOrdem == 2
			cOrdem := "%SRA.RA_FILIAL,SRA.RA_MAT%"
		ElseIf nOrdem == 3
			cOrdem := "%SRA.RA_FILIAL,SRA.RA_CC,SRA.RA_MAT%"
		ElseIf nOrdem == 4
			cOrdem := "%SRA.RA_FILIAL,SRA.RA_NOME%"
		EndIf
		
		BeginSql alias cAliasQry
				SELECT	SRA.RA_FILIAL, SRA.RA_CC,   SRA.RA_MAT,     SRA.RA_NOME, SRA.RA_NSOCIAL,  SRA.RA_SITFOLH, SRA.RA_CATFUNC, 
						SRA.RA_CHAPA,  SubStr( SRA.RA_NASC, 1, 4) AS ANO, SRA.RA_NASC, SRA.RA_SALARIO, SRA.RA_ESTCIVI,CTT.CTT_DESC01,ZAK.ZAK_DESCRI
				FROM %Table:SRA% SRA
				LEFT JOIN %Table:CTT% CTT on CTT.CTT_CUSTO = RA_CC      AND CTT.%notDel%  AND %exp:cFilSRACTT%
				LEFT JOIN %Table:ZAK% ZAK on ZAK.ZAK_COD   = RA_I_SETOR AND ZAK.%notDel%  AND %exp:cFilSRAZAK%
				WHERE SRA.RA_SITFOLH	IN	(%exp:Upper(cSitQuery)%) 	AND
					  SRA.RA_CATFUNC	IN	(%exp:Upper(cCatQuery)%)	AND
		   	 	      SRA.%notDel%    
				ORDER BY %exp:cOrdem%
		EndSql
		
	/*
	Prepara relatorio para executar a query gerada pelo Embedded SQL passando como 
	parametro a pergunta ou vetor com perguntas do tipo Range que foram alterados 
	pela funcao MakeSqlExpr para serem adicionados a query
	*/
	END REPORT QUERY oSection PARAM MV_PAR01, MV_PAR02, MV_PAR03, MV_PAR04, MV_PAR05, MV_PAR06
	
	// Define o total da regua da tela de processamento do relatorio
	oReport:SetMeter( 100 )  
	
	oSection:Print()	 // Imprimir
	
	// Termino do Relatorio                                        
	DBSelectArea( "SRA" )
	Set Filter to
	DBSetOrder(1)
	Set Device To Screen
	If nOrdem == 4 .Or. nOrdem == 5
		fErase( cArqNtx + OrdBagExt() )
	EndIf
Return

/*
===============================================================================================================================
Programa----------: fGP260Cond
Autor-------------: Alex Wallauer
Data da Criacao---: 10/08/2018
Descricao---------: Relacao de Aniversariantes do Mes
Parametros--------: cAliasQry
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function fGP260Cond(cAliasQry)////****
Local lRet	:= .T.            
Default cAliasQry	:= "SRA"                 
	
	
	// Consiste Filiais e Acessos                                             
	If !( (cAliasQry)->RA_FILIAL $ fValidFil() ) .Or. !Eval( cAcessaSRA )
		lRet	:= .F.			 	
	EndIf
	
	// Verifica Mes de Nascimento                                   
	If Month((cAliasQry)->RA_NASC) < nMesDe .Or. Month((cAliasQry)->RA_NASC) > nMesAte
		lRet	:= .F.
	EndIf    

Return lRet
