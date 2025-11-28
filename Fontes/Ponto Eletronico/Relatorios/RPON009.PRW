/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |15/05/2018| Chamado 24818. Inclusão da coluna da data e Totalizador por Funcionario
Lucas Borges  |17/09/2019| Chamado 28346. Retirada chamada da função itputx1.
Lucas Borges  |02/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
------------------------------------------------------------------------------------------------------------------------------- 
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RPON009
Autor-------------: Josué Danich Prestes
Data da Criacao---: 23/10/2015 
Descrição---------: Relatório totalizado de motivos de hora extras - Chamado 12240
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RPON009

Local  _oReport := nil
Public _cPerg 	:= "RPON009"

Pergunte(_cPerg,.T.)

_oReport 	:= RPON009REL()

_oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: RPON009REL
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/10/2015
Descrição---------: Imprimir relatório com totais de motivo de horas extras
Parametros--------: Nenhum
Retorno-----------: Objeto com relatório montado
===============================================================================================================================
*/
Static Function RPON009REL

Local 	_oReport	:= nil
Local 	_oSection1	:= nil
Local 	_oSection	:= nil
Local 	_oBreak		:= nil

_oReport := TReport():New("RPON009","Relatório Motivo Horas Extras","RPON009",{|_oReport| RPON009MAP(_oReport)},"Relatório Motivo Horas Extras",.T.)

_oSection := TRSection():New(_oReport,""	,{""})
_oSection:SetTotalInLine(.F.)
TRCell():New(_oSection,"FILIAL"		,/*Tabela*/,""	,/*Picture*/					,						,/*lPixel*/	,/*Block*/		 )

If MV_PAR09 == 1 //RELATÓRIO ANALÍTICO

	_oSection1 := TRSection():New(_oSection,"GERAL"		,{"FILIAL"})
	_oSection1:SetTotalInLine(.F.)
	
	TRCell():New(_oSection1,"FILIAL"		,/*Tabela*/,"Filial"			,"@!"					,05		,/*lPixel*/	,{||FILIAL	})
	TRCell():New(_oSection1,"SETOR"			,/*Tabela*/,"Setor"			,"@!"					,30		,/*lPixel*/	,;
	{||Posicione("ZAK",1,xFilial("ZAK")+AllTrim(Posicione("SRA",1,FILIAL+MAT,"RA_I_SETOR")),"ZAK_DESCRI")})
	
	TRCell():New(_oSection1,"MAT"			,/*Tabela*/,"Matricula"		,"@!"					,10 	,/*lPixel*/	,{||MAT})
	TRCell():New(_oSection1,"NOME"			,/*Tabela*/,"Nome"			,"@!"					,40 	,/*lPixel*/	,;
	{||Posicione("SRA",1,FILIAL+MAT,"RA_NOME")})

	TRCell():New(_oSection1,"DATA"  		,/*Tabela*/,"Data"			,"@D"					,10 	,/*lPixel*/	,{|| SToD(DATA) })
	
	TRCell():New(_oSection1,"CODMOT"		,/*Tabela*/,"Motivo HE"		,"@!"					,05 	,/*lPixel*/	,{||CODMOT	})
	TRCell():New(_oSection1,"DESCR"			,/*Tabela*/,"Descrição"		,"@!"					,40		,/*lPixel*/	,;
	{||IIf(Empty(CODMOT),"Sem motivo cadastrado",Posicione("SP6",1,FILIAL+CODMOT,"P6_DESC"))	})
	
	TRCell():New(_oSection1,"_nVlrPag"		,/*Tabela*/,"Total de horas"			,"@E 9,999,999,999.99" /*Picture*/	,16		,/*lPixel*/	,{||TOT	})
	
	_oSection1:PrintLine()

	_oBreak := TRBreak():New(_oSection1,_oSection1:Cell("MAT"),"Total do Funcionario : ") 
   TRFunction():New(_oSection1:Cell("_nVlrPag"),"","SUM",_oBreak,,,,.F.,.F.,.T.) 
	
	_oBreak := TRBreak():New(_oSection1,_oSection1:Cell("FILIAL"),"Total da filial : ") 
   TRFunction():New(_oSection1:Cell("_nVlrPag"),"","SUM",_oBreak,,,,.F.,.F.,.T.) 
	
			
ElseIf MV_PAR09 == 2 //RELATORIO SINTETICO

	_oSection1 := TRSection():New(_oSection,"GERAL",{"FILIAL"})
	_oSection1:SetTotalInLine(.F.)
	TRCell():New(_oSection1,"FILIAL"		,/*Tabela*/,"Filial"		,"@!"					,05		,/*lPixel*/	,{||FILIAL	})
	TRCell():New(_oSection1,"CODMOT"		,/*Tabela*/,"Motivo HE"		,"@!"					,05 	,/*lPixel*/	,{||CODMOT	})
	TRCell():New(_oSection1,"DESCR"			,/*Tabela*/,"Descrição"		,"@!"					,40		,/*lPixel*/	,;
	{||IIf(Empty(CODMOT),"Sem motivo cadastrado",Posicione("SP6",1,FILIAL+CODMOT,"P6_DESC"))	})
	
	TRCell():New(_oSection1,"_nVlrPag"		,/*Tabela*/,"Total de horas"			,"@E 9,999,999,999.99" /*Picture*/	,16		,/*lPixel*/	,{||TOT	})
	
	_oSection1:PrintLine()
	
	_oBreak := TRBreak():New(_oSection1,_oSection1:Cell("FILIAL"),"Total da filial : ") 
   TRFunction():New(_oSection1:Cell("_nVlrPag"),"","SUM",_oBreak,,,,.F.,.F.,.T.) 
	

EndIf

TRFunction():New(_oSection1:Cell("_nVlrPag"),/* cID */,"SUM",/*oBreak*/,"Total Geral",/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)

_oSection1:Cell("FILIAL"):SetHeaderAlign("LEFT")
_oSection1:Cell("CODMOT"):SetHeaderAlign("LEFT")
_oSection1:Cell("DESCR"):SetHeaderAlign("LEFT")  
_oSection1:Cell("_nVlrPag"):SetHeaderAlign("RIGHT")


Return _oReport

/*

===============================================================================================================================
Programa----------: RPON009MAP
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/10/2015
Descrição---------: Imprimir relatório com informações motivo hora extra
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RPON009MAP(_oReport)

Local _oSection1 := _oReport:Section(1):Section(1)

If MV_PAR09 == 1 //relatório analítico

	_oSection1:BeginQuery() 
	BeginSql alias "SPCT"

	SELECT GRP.FILIAL, GRP.MAT, GRP.DATA, GRP.CODMOT,SUM(GRP.TOT) AS TOT FROM (
	   	   
	   SELECT 		SPC.PC_FILIAL AS FILIAL,
	   				SPC.PC_MAT AS MAT,
	   				SPC.PC_DATA AS DATA,
	   				SPC.PC_I_MOTHE AS CODMOT,
	    		   	SUM(SPC.PC_QUANTC) AS TOT
	   		    
     	FROM %Table:SPC% SPC
                   
                   WHERE SPC.PC_FILIAL >= %Exp:MV_PAR01%
            				AND SPC.PC_FILIAL <= %Exp:MV_PAR02% 
			            	AND SPC.PC_DATA >= %Exp:DToS(MV_PAR03)%
			            	AND SPC.PC_DATA <= %Exp:DToS(MV_PAR04)%
            			 	AND SPC.PC_MAT >= %Exp:MV_PAR07%
            			 	AND SPC.PC_MAT <= %Exp:MV_PAR08%
            			 	AND SPC.PC_TIPOHE <> ' '
            			 	AND (SELECT SRA.RA_I_SETOR FROM  %Table:SRA% SRA 
            			 				WHERE SRA.RA_FILIAL = SPC.PC_FILIAL AND SRA.RA_MAT = SPC.PC_MAT
            			 						AND SRA.D_E_L_E_T_ = ' ' AND ROWNUM = 1) >= %Exp:MV_PAR05%
            			  	AND (SELECT SRA.RA_I_SETOR FROM  %Table:SRA% SRA 
            			 				WHERE SRA.RA_FILIAL = SPC.PC_FILIAL AND SRA.RA_MAT = SPC.PC_MAT
            			 						AND SRA.D_E_L_E_T_ = ' ' AND ROWNUM = 1) <= %Exp:MV_PAR06%
            			 	AND SPC.D_E_L_E_T_ = ' '
       
       GROUP BY SPC.PC_FILIAL,SPC.PC_MAT,SPC.PC_DATA,SPC.PC_I_MOTHE
        
       UNION ALL 
       
       SELECT 	SPH.PH_FILIAL AS FILIAL,
       			SPH.PH_MAT AS MAT,
   				SPH.PH_DATA AS DATA,
   				SPH.PH_I_MOTHE AS CODMOT,
    		   	SUM(SPH.PH_QUANTC) AS TOT
	   		    
     	FROM %Table:SPH% SPH
                   
                   WHERE SPH.PH_FILIAL >= %Exp:MV_PAR01%
            				AND SPH.PH_FILIAL <= %Exp:MV_PAR02% 
			            	AND SPH.PH_DATA >= %Exp:DToS(MV_PAR03)%
			            	AND SPH.PH_DATA <= %Exp:DToS(MV_PAR04)%
            			 	AND SPH.PH_MAT >= %Exp:MV_PAR07%
            			 	AND SPH.PH_MAT <= %Exp:MV_PAR08%
            			 	AND SPH.PH_TIPOHE <> ' '
            			 	AND (SELECT SRA.RA_I_SETOR FROM  %Table:SRA% SRA 
            			 				WHERE SRA.RA_FILIAL = SPH.PH_FILIAL AND SRA.RA_MAT = SPH.PH_MAT
            			 						AND SRA.D_E_L_E_T_ = ' ' AND ROWNUM = 1) >= %Exp:MV_PAR05%
            			  	AND (SELECT SRA.RA_I_SETOR FROM  %Table:SRA% SRA 
            			 				WHERE SRA.RA_FILIAL = SPH.PH_FILIAL AND SRA.RA_MAT = SPH.PH_MAT
            			 						AND SRA.D_E_L_E_T_ = ' ' AND ROWNUM = 1) <= %Exp:MV_PAR06%
            			 	AND SPH.D_E_L_E_T_ = ' '
       
       GROUP BY SPH.PH_FILIAL,SPH.PH_MAT,SPH.PH_DATA,SPH.PH_I_MOTHE
	    )GRP
	    
	    GROUP BY GRP.FILIAL,GRP.MAT,GRP.DATA,GRP.CODMOT
		ORDER BY GRP.FILIAL,GRP.MAT,GRP.DATA,GRP.CODMOT
	    
	       
	EndSql   

ElseIf MV_PAR09 == 2 //relatório sintético

	_oSection1:BeginQuery() 
	BeginSql alias "SPCT"

	SELECT GRP.FILIAL, GRP.CODMOT,SUM(GRP.TOT) AS TOT FROM (
	   	   
	   SELECT 		SPC.PC_FILIAL AS FILIAL,
	   				SPC.PC_I_MOTHE AS CODMOT,
	    		   	SUM(SPC.PC_QUANTC) AS TOT
	   		    
     	FROM %Table:SPC% SPC
                   
                   WHERE SPC.PC_FILIAL >= %Exp:MV_PAR01%
            				AND SPC.PC_FILIAL <= %Exp:MV_PAR02% 
			            	AND SPC.PC_DATA >= %Exp:DToS(MV_PAR03)%
			            	AND SPC.PC_DATA <= %Exp:DToS(MV_PAR04)%
            			 	AND SPC.PC_MAT >= %Exp:MV_PAR07%
            			 	AND SPC.PC_MAT <= %Exp:MV_PAR08%
            			 	AND SPC.PC_TIPOHE <> ' '
            			 	AND (SELECT SRA.RA_I_SETOR FROM  %Table:SRA% SRA 
            			 				WHERE SRA.RA_FILIAL = SPC.PC_FILIAL AND SRA.RA_MAT = SPC.PC_MAT
            			 						AND SRA.D_E_L_E_T_ = ' ' AND ROWNUM = 1) >= %Exp:MV_PAR05%
            			  	AND (SELECT SRA.RA_I_SETOR FROM  %Table:SRA% SRA 
            			 				WHERE SRA.RA_FILIAL = SPC.PC_FILIAL AND SRA.RA_MAT = SPC.PC_MAT
            			 						AND SRA.D_E_L_E_T_ = ' ' AND ROWNUM = 1) <= %Exp:MV_PAR06%
            			 	AND SPC.D_E_L_E_T_ = ' '
       
       GROUP BY SPC.PC_FILIAL,SPC.PC_I_MOTHE
        
       UNION ALL 
       
       SELECT 	SPH.PH_FILIAL AS FILIAL,
	   				SPH.PH_I_MOTHE AS CODMOT,
	    		   	SUM(SPH.PH_QUANTC) AS TOT
	   		    
     	FROM %Table:SPH% SPH
                   
                   WHERE SPH.PH_FILIAL >= %Exp:MV_PAR01%
            				AND SPH.PH_FILIAL <= %Exp:MV_PAR02% 
			            	AND SPH.PH_DATA >= %Exp:DToS(MV_PAR03)%
			            	AND SPH.PH_DATA <= %Exp:DToS(MV_PAR04)%
            			 	AND SPH.PH_MAT >= %Exp:MV_PAR07%
            			 	AND SPH.PH_MAT <= %Exp:MV_PAR08%
            			 	AND SPH.PH_TIPOHE <> ' '
            			 	AND (SELECT SRA.RA_I_SETOR FROM  %Table:SRA% SRA 
            			 				WHERE SRA.RA_FILIAL = SPH.PH_FILIAL AND SRA.RA_MAT = SPH.PH_MAT
            			 						AND SRA.D_E_L_E_T_ = ' ' AND ROWNUM = 1) >= %Exp:MV_PAR05%
            			  	AND (SELECT SRA.RA_I_SETOR FROM  %Table:SRA% SRA 
            			 				WHERE SRA.RA_FILIAL = SPH.PH_FILIAL AND SRA.RA_MAT = SPH.PH_MAT
            			 						AND SRA.D_E_L_E_T_ = ' ' AND ROWNUM = 1) <= %Exp:MV_PAR06%
            			 	AND SPH.D_E_L_E_T_ = ' '
       
       GROUP BY SPH.PH_FILIAL,SPH.PH_MAT,SPH.PH_I_MOTHE
	    )GRP
	    
	    GROUP BY GRP.FILIAL,GRP.CODMOT
		ORDER BY GRP.FILIAL,GRP.CODMOT
	    
	       
	EndSql   

EndIf

_oSection1:EndQuery()

_oReport:Section(1):Section(1):Init()

nInc	:= RecCount()
_oReport:SetMeter(nInc)

While !_oReport:Cancel() .And. SPCT->(!Eof())
	
	_oReport:Section(1):Section(1):PrintLine()
	SPCT->(DBSkip())

	If	SPCT->(Eof())
		_oReport:Section(1):Section(1):Finish()
	EndIf
	
EndDo

Return
