/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Talita		  |28/11/2013| Chamado 4553. Incluida query para analise das marcações dos pontos não apontadas conforme solicitado.
Lucas Borges  |17/09/2019| Chamado 28346. Retirada chamada da função itputx1.
Lucas Borges  |27/06/2025| Chamado 50617. Revisões diversas visando padronizar os fontes
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "Report.ch"

/*
===============================================================================================================================
Programa--------: RPON003
Autor-----------: Erich Mostaço Buttner
Data da Criacao-: 05/03/2013
Descrição-------: Relatorio utilizado para exibir as Não Marcação de Ponto dos Funcionarios
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function RPON003

Private cPerg		:= "RPON003" As Character
Private oReport		:= Nil As Object
Private oSecDados	:= Nil As Object

Pergunte(cPerg,.F.)

DEFINE REPORT oReport NAME cPerg TITLE "Marc. Não Apontadas" PARAMETER cPerg ACTION {|oReport| PrintReport(oReport)} Description "Marc. Não Apontadas da Filial Corrente."

//Seta Padrao de impressao como Paisagem
oReport:SetLandscape()
oReport:SetTotalInLine(.F.)              
                             
oReport:nFontBody	:= 08
oReport:cFontBody	:= "Courier New"  
oReport:nLineHeight	:= 50 // Define a altura da linha.

oReport:SetEdit(.F.)  //Desabilita a opcao de personalizar do relatorio         
oReport:SetEnvironment(2) //Deixa como cliente inicial a impressao               
oReport:SetMsgPrint('AGUARDE OS DADOS DO RELATORIO ESTAO SENDO PROCESSADOS')//mensagem exibida no momento da impressao

//Define dados da secao Filial

//Secao dados da Rede
DEFINE Section oSecDados OF oReport TITLE "Dados" TABLES "SPC","SRA","SP8", "RFE"

DEFINE CELL NAME "DATA_APONT"   	OF oSecDados ALIAS ""    TITLE "Data Apontamento"  	SIZE 12 
DEFINE CELL NAME "MATRICULA"    	OF oSecDados ALIAS ""    TITLE "Matricula"    		SIZE 06        
DEFINE CELL NAME "NOME"     		OF oSecDados ALIAS ""    TITLE "Nome"	    		SIZE 30        
DEFINE CELL NAME "NR_MARC_N_APONT"	OF oSecDados ALIAS ""    TITLE "Nro. Nao Apontam."  SIZE 10         

oSecDados:SetHeaderPage(.T.)  

oSecDados:Cell("DATA_APONT"):SetHeaderAlign("LEFT")  
oSecDados:Cell("MATRICULA"):SetHeaderAlign("LEFT")   
oSecDados:Cell("NOME"):SetHeaderAlign("LEFT")   
oSecDados:Cell("NR_MARC_N_APONT"):SetHeaderAlign("LEFT")   

oReport:PrintDialog()

Return               

/*
===============================================================================================================================
Programa--------: PrintReport
Autor-----------: Erich Mostaço Buttner
Data da Criacao-: 05/03/2013
Descrição-------: Realizaa a impressão
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function PrintReport(oReport As Object)

oReport:SetTitle("Marc. Não Apontadas")
oReport:Section(1):BeginQuery()

BeginSql alias "cQRY"
	SELECT (SubStr(P8.P8_DATAAPO, 7, 2) || '/' || SubStr(P8.P8_DATAAPO, 5, 2) || '/' || SubStr(P8.P8_DATAAPO, 1, 4)) DATA_APONT,
	       P8.P8_MAT MATRICULA, TRIM(RA.RA_NOME) NOME, COUNT(1) NR_MARC_N_APONT
	  FROM %Table:SP8% P8, %Table:SRA% RA
	 WHERE P8.D_E_L_E_T_ = ' '
	   AND RA.D_E_L_E_T_ = ' '
	   AND RA.RA_FILIAL = P8.P8_FILIAL
	   AND RA.RA_MAT = P8.P8_MAT
	   AND P8.P8_FILIAL = %xFilial:SRA%
	   AND P8.P8_DATAAPO BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
	   AND P8.P8_TPMCREP <> 'D'
	   AND P8.P8_MAT NOT IN
	       (SELECT PC.PC_MAT
	          FROM SPC010 PC
	         WHERE PC.D_E_L_E_T_ = ' '
	           AND PC.PC_FILIAL = %xFilial:SRA%
	           AND PC.PC_DATA = P8.P8_DATAAPO)
	 GROUP BY P8.P8_MAT, RA.RA_NOME, P8.P8_DATAAPO
	 ORDER BY P8.P8_DATAAPO, P8.P8_MAT
EndSql
oReport:Section(1):EndQuery()              

oSecDados:SetParentQuery() 
oSecDados:Print(.T.)     
      		
oReport:Section(1):BeginQuery()	
BeginSql alias "cQRY"
	SELECT (SubStr(RFE.RFE_DATA, 7, 2) || '/' || SubStr(RFE.RFE_DATA, 5, 2) || '/' || SubStr(RFE.RFE_DATA, 1, 4)) DATA_APONT,
	       RA.RA_MAT MATRICULA, RA.RA_NOME NOME, COUNT(1) NR_MARC_N_APONT
	  FROM %Table:RFE% RFE, %Table:SRA% RA
	 WHERE RFE.RFE_DATA BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
	   AND SubStr(RFE.RFE_PIS, 2, 12) = TRIM(RA.RA_PIS)
	   AND RFE.D_E_L_E_T_ = ' '
	   AND RA.D_E_L_E_T_ = ' '
	   AND RFE.RFE_DATAAP = ' '
	   AND RFE.RFE_FILIAL = %xFilial:RFE%
	 GROUP BY RFE.RFE_DATA, RA.RA_MAT, RA.RA_NOME, RFE.RFE_PIS
	 ORDER BY RFE.RFE_DATA, RA.RA_MAT
EndSql

oReport:Section(1):EndQuery()  
		
oSecDados:SetParentQuery() 
oSecDados:Print(.T.)       

Return
