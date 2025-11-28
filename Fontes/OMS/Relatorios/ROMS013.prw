/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |14/03/2016| Chamado 14726. Separado valores de INSS e SEST
Alex Wallauer |17/10/2016| Chamado 17222. Inclusão do valor do pedágio no RPA
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

#Include "report.ch"
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: ROMS013
Autor-----------: Fabiano Dias Silva
Data da Criacao-: 20/01/2010
Descrição-------: Relatorio utilizado para gerar relacao de RPA por Filial/Autonomo Sintetico/Analitico.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ROMS013()
                                
Private cFilCorre:=cFilAnt //Armazena a filial corrente, pois na busca por autonomos eh necessario passar a filial 01 para que quando acessado os parametros por outras filiais mostre os autonomos

Private cPerg := "ROMS013"
Private QRY1,QRY2,QRY3,QRY4        
Private oZZ2FIL_1,oZZ2_1,oZZ2_2,oZZ2_3,oZZ2_4,oZZ2_5,oZZ2_6                      
Private oBrkFiSint,oBrkAutAna,oBrkFilAna,oBrkAnaAut
Private aOrd  := {"Por Filial","Por Autonomo"} 

Private cNomeFil  := ""
Private cNomeAuton:= ""
Private cNomAutAna:= ""          

cFilAnt:= "01"

Pergunte(cPerg,.F.)

DEFINE REPORT oReport NAME cPerg TITLE "Relação de Valores por Filial/Autonomo Sintetico/Analitico" PARAMETER cPerg ACTION {|oReport| ROMS013P(oReport)} 

//Seta Padrao de impressao Retrato
oReport:SetPortrait()
oReport:SetTotalInLine(.F.)                

//=================================================
//Define secoes para primeira ordem - Filial    
//=================================================

//=================================================
//Secao Filial Sintetica
//=================================================
DEFINE Section oZZ2FIL_1 OF oReport TITLE "Dados" TABLES "ZZ2","SRA" ORDERS aOrd

DEFINE CELL NAME "zz2_filial"	OF oZZ2FIL_1 ALIAS "ZZ2"  TITLE "Cod "
DEFINE CELL NAME "NOMFIL"	    OF oZZ2FIL_1 ALIAS "" BLOCK{|| ROMS013GF(QRY1->zz2_filial)} TITLE "Filial" SIZE 20
oZZ2FIL_1:Disable()

DEFINE Section oZZ2_1 OF oZZ2FIL_1 TITLE "Dados" TABLES "ZZ2","SRA"

DEFINE CELL NAME "ra_mat"	        OF oZZ2_1 ALIAS "SRA" TITLE "Matricula"      SIZE 14
DEFINE CELL NAME "Nome_Autonomo"    OF oZZ2_1 ALIAS ""    TITLE "Nome"           SIZE 40 BLOCK{|| QRY1->A2_COD + '-'+ QRY1->RA_NOME}     
DEFINE CELL NAME "ra_pis"	        OF oZZ2_1 ALIAS "SRA" TITLE "PIS"            SIZE 14 
DEFINE CELL NAME "cic"    	        OF oZZ2_1 ALIAS ""    TITLE "CPF"            SIZE 22 PICTURE "@R 999.999.999-99"
DEFINE CELL NAME "QTDRECIBO"	    OF oZZ2_1 ALIAS ""    TITLE "Recibos"        SIZE 10 PICTURE "@E 9,999,999"
DEFINE CELL NAME "TOTAL"	        OF oZZ2_1 ALIAS ""    TITLE "Proventos"      SIZE 20 PICTURE "@E 9,999,999,999.99"
DEFINE CELL NAME "PEDAGIO"          OF oZZ2_1 ALIAS ""    TITLE "Pedagios"       SIZE 15 PICTURE "@E 999,999,999.99"
DEFINE CELL NAME "INSS"	            OF oZZ2_1 ALIAS ""    TITLE "INSS"           SIZE 15 PICTURE "@E 999,999,999.99"
DEFINE CELL NAME "SEST"	            OF oZZ2_1 ALIAS ""    TITLE "SEST"           SIZE 15 PICTURE "@E 999,999,999.99"
DEFINE CELL NAME "IRRF"	            OF oZZ2_1 ALIAS ""    TITLE "IRRF"           SIZE 15 PICTURE "@E 999,999,999.99"
oZZ2_1:Disable()
oZZ2_1:SetTotalInLine(.F.)                                               

oZZ2_1:OnPrintLine({|| cNomeFil := QRY1->zz2_filial  + " - " + ROMS013GF(QRY1->zz2_filial)})

//=================================================
//Alinhamento de cabecalho
//=================================================
oZZ2_1:Cell("QTDRECIBO"):SetHeaderAlign("RIGHT")       
oZZ2_1:Cell("TOTAL"):SetHeaderAlign("RIGHT")  
oZZ2_1:Cell("PEDAGIO"):SetHeaderAlign("RIGHT")  
oZZ2_1:Cell("INSS"):SetHeaderAlign("RIGHT") 
oZZ2_1:Cell("SEST"):SetHeaderAlign("RIGHT")       
oZZ2_1:Cell("IRRF"):SetHeaderAlign("RIGHT") 

//=================================================
//Define secoes para primeira ordem - Filial    
//=================================================
//=================================================
//Secao Filial Analitica
//=================================================
DEFINE Section oZZ2_2 OF oZZ2FIL_1 TITLE "Dados" TABLES "SRA"

DEFINE CELL NAME "ra_mat"	        OF oZZ2_2 ALIAS "SRA" TITLE "Matricula"     
DEFINE CELL NAME "Nome_Autonomo"    OF oZZ2_2 ALIAS ""    TITLE "Nome"           SIZE 40 BLOCK{|| QRY1->A2_COD + ' - '+ QRY1->RA_NOME}
DEFINE CELL NAME "ra_pis"	        OF oZZ2_2 ALIAS "SRA" TITLE "PIS"            SIZE 12 
DEFINE CELL NAME "ra_cic"    	    OF oZZ2_2 ALIAS "SRA" TITLE "CPF"            SIZE 16 PICTURE "@R 999.999.999-99"                                               
oZZ2_2:Disable()                                                                              

oZZ2_2:OnPrintLine({|| cNomeAuton := QRY1->A2_COD + ' - '+ QRY1->RA_NOME })

DEFINE Section oZZ2_3 OF oZZ2_2    TITLE "Dados" TABLES "ZZ2"

DEFINE CELL NAME "zz2_data"	        OF oZZ2_3 ALIAS "ZZ2" TITLE "Data"           SIZE 12
DEFINE CELL NAME "zz2_recibo"	    OF oZZ2_3 ALIAS "ZZ2" TITLE "Recibo"         SIZE 12    
DEFINE CELL NAME "zz2_total"	    OF oZZ2_3 ALIAS "ZZ2" TITLE "Proventos"      SIZE 20 PICTURE "@E 9,999,999,999.99" 
DEFINE CELL NAME "PEDAGIO"          OF oZZ2_3 ALIAS "ZZ2" TITLE "Pedagios"       SIZE 18 PICTURE "@E 999,999,999.99" 
DEFINE CELL NAME "inss"             OF oZZ2_3 ALIAS ""    TITLE "INSS"           SIZE 18 PICTURE "@E 999,999,999.99"    
DEFINE CELL NAME "SEST"             OF oZZ2_3 ALIAS ""    TITLE "SEST"           SIZE 18 PICTURE "@E 999,999,999.99"                                                 
DEFINE CELL NAME "zz2_irrf"         OF oZZ2_3 ALIAS "ZZ2" TITLE "IRRF"           SIZE 18 PICTURE "@E 999,999,999.99"                                               
oZZ2_3:Disable()                                                  
oZZ2_3:SetTotalInLine(.F.) 

oZZ2_3:OnPrintLine({|| cNomeFil := QRY1->zz2_filial  + " - " + ROMS013GF(QRY1->zz2_filial)})

//=================================================
//Alinhamento de cabecalho
//=================================================
oZZ2_3:Cell("zz2_recibo"):SetHeaderAlign("RIGHT")       
oZZ2_3:Cell("zz2_total"):SetHeaderAlign("RIGHT")  
oZZ2_3:Cell("PEDAGIO" ):SetHeaderAlign("RIGHT")  
oZZ2_3:Cell("INSS"):SetHeaderAlign("RIGHT")   
oZZ2_3:Cell("SEST"):SetHeaderAlign("RIGHT")       
oZZ2_3:Cell("zz2_irrf"):SetHeaderAlign("RIGHT")   

//=================================================
//Alinhamento da Celula                            
//=================================================     
oZZ2_3:Cell("zz2_recibo"):SetAlign("RIGHT")                  

//=================================================
//Define secoes para segunda ordem - Autonomo   
//=================================================
//=================================================
//Autonomo - Sintetico
//=================================================
DEFINE Section oZZ2_4 OF oReport    TITLE "Dados" TABLES "ZZ2","SRA"

DEFINE CELL NAME "ra_mat"	        OF oZZ2_4 ALIAS "SRA" TITLE "Matricula"      SIZE 14
DEFINE CELL NAME "Nome_Autonomo"    OF oZZ2_4 ALIAS ""    TITLE "Nome"           SIZE 38 BLOCK{|| QRY2->A2_COD + '-' + QRY2->RA_NOME}
DEFINE CELL NAME "ra_pis"	        OF oZZ2_4 ALIAS "SRA" TITLE "PIS"            SIZE 14 
DEFINE CELL NAME "ra_cic"    	    OF oZZ2_4 ALIAS ""    TITLE "CPF"            SIZE 22 PICTURE "@R 999.999.999-99"
DEFINE CELL NAME "TOTAL"	        OF oZZ2_4 ALIAS ""    TITLE "Proventos"      SIZE 20 PICTURE "@E 9,999,999,999.99"
DEFINE CELL NAME "PEDAGIO"          OF oZZ2_4 ALIAS ""    TITLE "Pedagios"       SIZE 15 PICTURE "@E 999,999,999.99"
DEFINE CELL NAME "INSS"	            OF oZZ2_4 ALIAS ""    TITLE "INSS"           SIZE 15 PICTURE "@E 999,999,999.99"
DEFINE CELL NAME "SEST"	            OF oZZ2_4 ALIAS ""    TITLE "SEST"           SIZE 15 PICTURE "@E 999,999,999.99"
DEFINE CELL NAME "IRRF"	            OF oZZ2_4 ALIAS ""    TITLE "IRRF"           SIZE 15 PICTURE "@E 999,999,999.99"
oZZ2_4:Disable()
oZZ2_4:SetTotalInLine(.F.)                                         

//Alinhamento de cabecalho
oZZ2_4:Cell("TOTAL"):SetHeaderAlign("RIGHT")  
oZZ2_4:Cell("PEDAGIO"):SetHeaderAlign("RIGHT")  
oZZ2_4:Cell("INSS"):SetHeaderAlign("RIGHT")   
oZZ2_4:Cell("SEST"):SetHeaderAlign("RIGHT")    
oZZ2_4:Cell("IRRF"):SetHeaderAlign("RIGHT")


//=================================================
//Define secoes para segunda ordem - Autonomo   
//=================================================
//=================================================
//Autonomo - Analitico   
//================================================= 
DEFINE Section oZZ2_5 OF oReport TITLE "Dados" TABLES "SRA"

DEFINE CELL NAME "ra_mat"	        OF oZZ2_5 ALIAS "SRA" TITLE "Matricula" 
DEFINE CELL NAME "Nome_Aut"         OF oZZ2_5 ALIAS ""    TITLE "Nome"           SIZE 40 BLOCK{|| QRY3->A2_COD + ' - ' + QRY3->RA_NOME}     
DEFINE CELL NAME "ra_pis"	        OF oZZ2_5 ALIAS "SRA" TITLE "PIS"            SIZE 12 
DEFINE CELL NAME "ra_cic"    	    OF oZZ2_5 ALIAS "SRA" TITLE "CPF"            SIZE 16 PICTURE "@R 999.999.999-99"                                               
oZZ2_5:Disable()                                                                             

DEFINE Section oZZ2_6 OF oZZ2_5  TITLE "Dados" TABLES "ZZ2"
                                                                                       
DEFINE CELL NAME "filial"	        OF oZZ2_6 ALIAS ""    TITLE "Filial"         SIZE 30 BLOCK{|| QRY3->zz2_filial + '-' + ROMS013GF(QRY3->zz2_filial)}
DEFINE CELL NAME "total"	        OF oZZ2_6 ALIAS "ZZ2" TITLE "Proventos"      SIZE 20 PICTURE "@E 9,999,999,999.99" 
DEFINE CELL NAME "PEDAGIO"          OF oZZ2_6 ALIAS "ZZ2" TITLE "Pedagios"       SIZE 18 PICTURE "@E 999,999,999.99" 
DEFINE CELL NAME "inss"             OF oZZ2_6 ALIAS ""    TITLE "INSS"           SIZE 18 PICTURE "@E 999,999,999.99"   
DEFINE CELL NAME "SEST"             OF oZZ2_6 ALIAS ""    TITLE "SEST"           SIZE 18 PICTURE "@E 999,999,999.99"                                              
DEFINE CELL NAME "irrf"             OF oZZ2_6 ALIAS "ZZ2" TITLE "IRRF"           SIZE 18 PICTURE "@E 999,999,999.99"                                               
oZZ2_6:Disable()                                                  
oZZ2_6:SetTotalInLine(.F.)        

oZZ2_6:OnPrintLine({|| cNomAutAna := QRY3->A2_COD + ' - ' + QRY3->RA_NOME })                                                            
                                                                                             
//=================================================
//Alinhamento de cabecalho
//=================================================
oZZ2_6:Cell("TOTAL"):SetHeaderAlign("RIGHT")  
oZZ2_6:Cell("PEDAGIO" ):SetHeaderAlign("RIGHT")  
oZZ2_6:Cell("INSS"):SetHeaderAlign("RIGHT")  
oZZ2_6:Cell("SEST"):SetHeaderAlign("RIGHT")       
oZZ2_6:Cell("IRRF"):SetHeaderAlign("RIGHT")

oReport:PrintDialog()

cFilAnt:= cFilCorre

Return               

/*
===============================================================================================================================
Programa--------: ROMS013P
Autor-----------: Fabiano Dias Silva
Data da Criacao-: 20/01/2010
Descrição-------: Montagem do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS013P(oReport)

Local _cFilDtZZ2 	:= "%"
Local _cFiltroDt	:= "%"
Local _cFiltro  	:= "%"

Private nOrdem := oZZ2FIL_1:GetOrder() //Busca ordem selecionada pelo usuario   

cFilAnt:= cFilCorre

oReport:SetTitle("Relação de Valores  " + aOrd[nOrdem] + If(MV_PAR05 == 1," Sintético ", " Analítico ") + " - Emissao de " + DToC(MV_PAR01) + " até "  + DToC(MV_PAR02))

//=================================================
//Filtros
//=================================================
//=================================================
//Da Emissao Ate Emissao
//=================================================
If !Empty(MV_PAR01) .And. !Empty(MV_PAR02)
	_cFiltroDt += " AND zz3.zz3_data BETWEEN '" + DToS(MV_PAR01) + "' AND '" + DToS(MV_PAR02) + "'"
	_cFilDtZZ2 += " AND zz2.zz2_data BETWEEN '" + DToS(MV_PAR01) + "' AND '" + DToS(MV_PAR02) + "'"
EndIf	

//=================================================
//Do Autonomo ate Autonomo      
//=================================================
_cFiltro += " AND zz2.zz2_autono BETWEEN '" + MV_PAR03 + "' AND '" + MV_PAR04 + "'"

//=================================================
//Considerar Autonomo Demitido (1=SIM 2=NAO)  
//================================================= 
If MV_PAR06 = 2
	_cFiltro += " AND RA.RA_SITFOLH <> 'D'"
EndIf

//============================================================
//Considerar apenas Autonomos que tiveram a retencao de IRRF 
//============================================================
If MV_PAR07 = 2
	_cFiltro += " AND ZZ2.ZZ2_IRRF > 0 "
EndIf


_cFiltro   += "%"
_cFiltroDt += "%"
_cFilDtZZ2 += "%"

//=================================================               
//Por Filial
//=================================================
If nOrdem == 1    
    
    //=================================================
    //Por Filial - Sintetico                           
    //=================================================                                
	If MV_PAR05 == 1                                                     
	
		oZZ2FIL_1:Enable()
		oZZ2_1:Enable()                     
		
		//=================================================
		//Quebra por Filial - Sintetico		
		//=================================================
		oBrkFiSint:= TRBreak():New(oZZ2_1,oZZ2FIL_1:CELL("zz2_filial"),"Totais: " + cNomeFil,.F.)          
		oBrkFiSint:SetTotalText({|| "Totais " + cNomeFil})
		
		TRFunction():New(oZZ2_1:Cell("TOTAL")    ,NIL,"SUM",oBrkFiSint,NIL,NIL,NIL,.F.,.T.)
		TRFunction():New(oZZ2_1:Cell("PEDAGIO")  ,NIL,"SUM",oBrkFiSint,NIL,NIL,NIL,.F.,.T.)
		TRFunction():New(oZZ2_1:Cell("INSS")     ,NIL,"SUM",oBrkFiSint,NIL,NIL,NIL,.F.,.T.)
		TRFunction():New(oZZ2_1:Cell("SEST")     ,NIL,"SUM",oBrkFiSint,NIL,NIL,NIL,.F.,.T.)
		TRFunction():New(oZZ2_1:Cell("IRRF")     ,NIL,"SUM",oBrkFiSint,NIL,NIL,NIL,.F.,.T.)
		TRFunction():New(oZZ2_1:Cell("QTDRECIBO"),NIL,"SUM",oBrkFiSint,NIL,NIL,NIL,.F.,.T.)
		
		//=================================================
		//Executa query para consultar Dados
		//=================================================
		BEGIN REPORT QUERY oZZ2FIL_1
			BeginSql alias "QRY1"   	   	
			   	SELECT 
					zz2.zz2_filial, ra.ra_mat,
					(SELECT MIN(A2.A2_COD) FROM SA2010 A2 WHERE A2.D_E_L_E_T_ = ' ' AND (RA.RA_MAT = A2.A2_I_AUTAV OR RA.RA_MAT = A2.A2_I_AUT)) as a2_cod,
					ra.ra_nome,ra.ra_pis,Trim(ra.ra_cic) cic,SUM(ZZ2.ZZ2_VRPEDA) PEDAGIO ,
					sum(zz2.zz2_total) TOTAL,sum(zz2.zz2_inss) INSS, sum(zz2.zz2_sest) SEST,sum(zz2.zz2_irrf) IRRF,COUNT(ZZ2.zz2_recibo) QTDRECIBO
				FROM 
					%Table:ZZ2% ZZ2    
					JOIN %Table:SRA% RA ON zz2.zz2_autono = RA.ra_mat 
				WHERE 
					ZZ2.%notDel%  
					AND RA.%notDel%  
					AND RA.ra_catfunc = 'A'
					AND ((ZZ2.ZZ2_ORIGEM = '1' AND ZZ2.ZZ2_RECIBO  =  ( SELECT DISTINCT ZZ3.ZZ3_RECIBO  FROM %Table:ZZ3%  ZZ3  WHERE ZZ3.D_E_L_E_T_ = ' '  AND ZZ2.ZZ2_FILIAL   = ZZ3.ZZ3_FILIAL  AND ZZ2.ZZ2_RECIBO   = ZZ3.ZZ3_RECIBO  %exp:_cFiltroDt%  ) ) OR ZZ2.ZZ2_ORIGEM <> '1' %exp:_cFilDtZZ2%)
					AND RA.RA_FILIAL = '01'
					%exp:_cFiltro%					
			    GROUP BY
			   		zz2.zz2_filial,ra.ra_mat,ra.ra_pis,RA.ra_cic,ra.ra_nome,3
				ORDER BY 
					zz2.zz2_filial,ra.ra_mat
			EndSql
		END REPORT QUERY oZZ2FIL_1               
	
		oZZ2_1:SetParentQuery()
		oZZ2_1:SetParentFilter({|cParam| QRY1->zz2_filial == cParam},{|| QRY1->zz2_filial})
	
		oZZ2FIL_1:Print(.T.)
	    
	    //=================================================    
		//Por Filial - Analitico
		//=================================================
		Else                
			
			oZZ2FIL_1:Enable()
			oZZ2_2:Enable()
			oZZ2_3:Enable()
			
			//=================================================
			//Quebra por Autonomo
			//=================================================
			oBrkAutAna := TRBreak():New(oZZ2_3,oZZ2_2:CELL("ra_mat"),"Total Autonomo: " + cNomeAuton,.F.)          
			oBrkAutAna :SetTotalText({|| "Total Autonomo: " + cNomeAuton })
			
			//=================================================
			//Totalizadores por Autonomo                       
			//=================================================                                                                  
			TRFunction():New(oZZ2_3:Cell("zz2_recibo"),NIL,"COUNT",oBrkAutAna,NIL,NIL,NIL,.F.,.F.)
			TRFunction():New(oZZ2_3:Cell("zz2_total") ,NIL,"SUM"  ,oBrkAutAna,NIL,NIL,NIL,.F.,.F.)
			TRFunction():New(oZZ2_3:Cell("PEDAGIO")   ,NIL,"SUM"  ,oBrkAutAna,NIL,NIL,NIL,.F.,.F.)
			TRFunction():New(oZZ2_3:Cell("INSS")      ,NIL,"SUM"  ,oBrkAutAna,NIL,NIL,NIL,.F.,.F.)
			TRFunction():New(oZZ2_3:Cell("SEST")      ,NIL,"SUM"  ,oBrkAutAna,NIL,NIL,NIL,.F.,.F.)
			TRFunction():New(oZZ2_3:Cell("zz2_irrf")  ,NIL,"SUM"  ,oBrkAutAna,NIL,NIL,NIL,.F.,.F.)
			
			//=================================================
			//Quebra por Filial - Analitico                    
			//=================================================       
			oBrkFilAna := TRBreak():New(oReport,oZZ2FIL_1:CELL("zz2_filial"),"Totais: " + cNomeFil,.F.)
			oBrkFilAna :SetTotalText({|| "Totais: " + cNomeFil }) 
			
			//=================================================
			//Totalizadores por Filial - Analitico             
			//=================================================                                                                            
			TRFunction():New(oZZ2_3:Cell("zz2_recibo"),NIL,"COUNT",oBrkFilAna,NIL,NIL,NIL,.F.,.T.)
			TRFunction():New(oZZ2_3:Cell("zz2_total") ,NIL,"SUM"  ,oBrkFilAna,NIL,NIL,NIL,.F.,.T.)
			TRFunction():New(oZZ2_3:Cell("PEDAGIO")   ,NIL,"SUM"  ,oBrkAutAna,NIL,NIL,NIL,.F.,.F.)
			TRFunction():New(oZZ2_3:Cell("INSS")      ,NIL,"SUM"  ,oBrkFilAna,NIL,NIL,NIL,.F.,.T.)
			TRFunction():New(oZZ2_3:Cell("SEST")      ,NIL,"SUM"  ,oBrkFilAna,NIL,NIL,NIL,.F.,.T.)
			TRFunction():New(oZZ2_3:Cell("zz2_irrf")  ,NIL,"SUM"  ,oBrkFilAna,NIL,NIL,NIL,.F.,.T.)
		
			//=================================================
			//Executa query para consultar Dados
			//=================================================
			BEGIN REPORT QUERY oZZ2FIL_1
				BeginSql alias "QRY1"   	   	
			   		SELECT 
						zz2.zz2_filial, ra.ra_mat,
						(SELECT MIN(A2.A2_COD) FROM SA2010 A2 WHERE A2.D_E_L_E_T_ = ' ' AND (RA.RA_MAT = A2.A2_I_AUTAV OR RA.RA_MAT = A2.A2_I_AUT)) as a2_cod,
						ra.ra_nome,ra.ra_pis,ra.ra_cic,zz2.zz2_total,
						zz2.zz2_inss INSS, zz2.zz2_sest SEST,zz2.zz2_irrf,zz2.zz2_recibo, ZZ2.ZZ2_VRPEDA PEDAGIO ,
						Case 
						WHEN ZZ2.ZZ2_ORIGEM = '1' THEN ( SELECT DISTINCT zz3.zz3_data FROM ZZ3010 ZZ3 WHERE ZZ3.D_E_L_E_T_ = ' ' AND ZZ2.ZZ2_FILIAL = ZZ3.ZZ3_FILIAL AND ZZ2.ZZ2_RECIBO = ZZ3.ZZ3_RECIBO ) 
						Else ZZ2.ZZ2_DATA
						END zz2_data
					FROM 
						%Table:ZZ2% ZZ2
						JOIN %Table:SRA% RA ON zz2.zz2_autono = RA.ra_mat 
					WHERE 
						ZZ2.%notDel%  
						AND RA.%notDel%  
						AND RA.ra_catfunc = 'A'     
						AND ((ZZ2.ZZ2_ORIGEM = '1' AND ZZ2.ZZ2_RECIBO  =  ( SELECT DISTINCT ZZ3.ZZ3_RECIBO  FROM %Table:ZZ3%  ZZ3  WHERE ZZ3.D_E_L_E_T_ = ' '  AND ZZ2.ZZ2_FILIAL   = ZZ3.ZZ3_FILIAL  AND ZZ2.ZZ2_RECIBO   = ZZ3.ZZ3_RECIBO  %exp:_cFiltroDt%  ) ) OR ZZ2.ZZ2_ORIGEM <> '1' %exp:_cFilDtZZ2%)
						AND RA.RA_FILIAL = '01'
						%exp:_cFiltro%
					ORDER BY 
						zz2.zz2_filial,ra.ra_mat,zz2_data
				EndSql
			END REPORT QUERY oZZ2FIL_1               
	
		oZZ2_2:SetParentQuery()
		oZZ2_2:SetParentFilter({|cParam| QRY1->zz2_filial == cParam},{|| QRY1->zz2_filial})
		
		oZZ2_3:SetParentQuery()
		oZZ2_3:SetParentFilter({|cParam| QRY1->zz2_filial + QRY1->ra_mat == cParam},{|| QRY1->zz2_filial + QRY1->ra_mat})
	
		oZZ2FIL_1:Print(.T.)
		
	EndIf              

//=================================================
//Ordem por Autonomo
//=================================================
Else     

	//=================================================
    //Autonomo - Sintetico                             
    //=================================================                              
	If MV_PAR05 == 1   
						
		oZZ2_4:Enable()   
						
		//=================================================
		//Totalizadores
		//=================================================
		TRFunction():New(oZZ2_4:Cell("TOTAL")    ,NIL,"SUM",NIL,NIL,NIL,NIL,.F.,.T.)
		TRFunction():New(oZZ2_4:Cell("PEDAGIO")  ,NIL,"SUM",NIL,NIL,NIL,NIL,.F.,.T.)
		TRFunction():New(oZZ2_4:Cell("INSS")     ,NIL,"SUM",NIL,NIL,NIL,NIL,.F.,.T.)
		TRFunction():New(oZZ2_4:Cell("SEST")     ,NIL,"SUM",NIL,NIL,NIL,NIL,.F.,.T.)
		TRFunction():New(oZZ2_4:Cell("IRRF")     ,NIL,"SUM",NIL,NIL,NIL,NIL,.F.,.T.)
						
		//=================================================
		//Executa query para consultar Dados
		//=================================================
		BEGIN REPORT QUERY oZZ2_4
		BeginSql alias "QRY2"   	   	
			   				SELECT 
								ra.ra_mat,
								(SELECT MIN(A2.A2_COD) FROM SA2010 A2 WHERE A2.D_E_L_E_T_ = ' ' AND (RA.RA_MAT = A2.A2_I_AUTAV OR RA.RA_MAT = A2.A2_I_AUT)) as a2_cod,
								ra.ra_nome,ra.ra_pis,ra.ra_cic, sum(ZZ2.ZZ2_VRPEDA) PEDAGIO ,
								sum(zz2.zz2_total) TOTAL,sum(zz2.zz2_inss) INSS, sum(zz2.zz2_sest) SEST,sum(zz2.zz2_irrf) IRRF
							FROM 
								%Table:ZZ2% ZZ2
								JOIN %Table:SRA% RA ON zz2.zz2_autono = RA.ra_mat 
							WHERE 
								ZZ2.%notDel%  
								AND RA.%notDel%  
								AND RA.ra_catfunc = 'A'
								AND ((ZZ2.ZZ2_ORIGEM = '1' AND ZZ2.ZZ2_RECIBO  =  ( SELECT DISTINCT ZZ3.ZZ3_RECIBO  FROM %Table:ZZ3%  ZZ3  WHERE ZZ3.D_E_L_E_T_ = ' '  AND ZZ2.ZZ2_FILIAL   = ZZ3.ZZ3_FILIAL  AND ZZ2.ZZ2_RECIBO   = ZZ3.ZZ3_RECIBO  %exp:_cFiltroDt%  ) ) OR ZZ2.ZZ2_ORIGEM <> '1' %exp:_cFilDtZZ2%)
								AND RA.RA_FILIAL = '01'
								%exp:_cFiltro%
						    GROUP BY
						   		ra.ra_mat,ra.ra_pis,RA.ra_cic,ra.ra_nome,2
							ORDER BY 
								ra.ra_mat
							EndSql
		END REPORT QUERY oZZ2_4               
	
		oZZ2_4:Print(.T.)
				    
	//=================================================
	//Autonomo - Analitico
	//=================================================	
	Else           
						
		oZZ2_5:Enable()
		oZZ2_6:Enable()       
						
		//=================================================
		//Quebra por Autonomo	  					         
		//=================================================      
		oBrkAnaAut:= TRBreak():New(oZZ2_6,oZZ2_5:CELL("ra_mat"),"Total: " + cNomAutAna,.F.) 
		oBrkAnaAut:SetTotalText({|| "Total: " + cNomAutAna})
             
		//=================================================
		//Totalizadores
		//=================================================
		TRFunction():New(oZZ2_6:Cell("TOTAL")    ,NIL,"SUM",oBrkAnaAut,NIL,NIL,NIL,.F.,.T.)
		TRFunction():New(oZZ2_6:Cell("PEDAGIO")  ,NIL,"SUM",oBrkAnaAut,NIL,NIL,NIL,.F.,.T.)
		TRFunction():New(oZZ2_6:Cell("INSS")     ,NIL,"SUM",oBrkAnaAut,NIL,NIL,NIL,.F.,.T.)
		TRFunction():New(oZZ2_6:Cell("SEST")     ,NIL,"SUM",oBrkAnaAut,NIL,NIL,NIL,.F.,.T.)
		TRFunction():New(oZZ2_6:Cell("IRRF")     ,NIL,"SUM",oBrkAnaAut,NIL,NIL,NIL,.F.,.T.)  
							         
		//=================================================
		//Executa query para consultar Dados
		//=================================================
		BEGIN REPORT QUERY oZZ2_5
					BeginSql alias "QRY3"   	   	
			   				SELECT 
								zz2.zz2_filial,ra.ra_mat,
								(SELECT MIN(A2.A2_COD) FROM SA2010 A2 WHERE A2.D_E_L_E_T_ = ' ' AND (RA.RA_MAT = A2.A2_I_AUTAV OR RA.RA_MAT = A2.A2_I_AUT)) as a2_cod,
								ra.ra_nome,ra.ra_pis,ra.ra_cic, SUM(ZZ2.ZZ2_VRPEDA) PEDAGIO ,
								sum(zz2.zz2_total) TOTAL,sum(zz2.zz2_inss) INSS, SUM(zz2.zz2_sest) SEST,sum(zz2.zz2_irrf) IRRF
							FROM 
								%Table:ZZ2% ZZ2
								JOIN %Table:SRA% RA ON zz2.zz2_autono = RA.ra_mat 
							WHERE 
								ZZ2.%notDel%  
								AND RA.%notDel%  
								AND RA.ra_catfunc = 'A'
								AND ((ZZ2.ZZ2_ORIGEM = '1' AND ZZ2.ZZ2_RECIBO  =  ( SELECT DISTINCT ZZ3.ZZ3_RECIBO  FROM %Table:ZZ3%  ZZ3  WHERE ZZ3.D_E_L_E_T_ = ' '  AND ZZ2.ZZ2_FILIAL   = ZZ3.ZZ3_FILIAL  AND ZZ2.ZZ2_RECIBO   = ZZ3.ZZ3_RECIBO  %exp:_cFiltroDt%  ) ) OR ZZ2.ZZ2_ORIGEM <> '1' %exp:_cFilDtZZ2%)
								AND RA.RA_FILIAL = '01'
								%exp:_cFiltro%
						    GROUP BY
						   		zz2.zz2_filial,ra.ra_mat,ra.ra_pis,RA.ra_cic,ra.ra_nome,3
							ORDER BY 
								ra.ra_mat,zz2.zz2_filial
							EndSql
		END REPORT QUERY oZZ2_5               
	
		oZZ2_6:SetParentQuery()
		oZZ2_6:SetParentFilter({|cParam| QRY3->ra_mat == cParam},{|| QRY3->ra_mat})
	
		oZZ2_5:Print(.T.)
				
	EndIf

EndIf
     
Return

/*
===============================================================================================================================
Programa--------: ROMS013GF
Autor-----------: Jeovane
Data da Criacao-: 29/07/2009
Descrição-------: Retorna o nome da filial
Parametros------: _cCodFil : Codigo da Filial a ser retornado o nome
Retorno---------: _cRet - Nome da filial
===============================================================================================================================
*/
Static Function ROMS013GF(_cCodFil)

Local _aAreaSM0 := SM0->(getArea())
Local _cRet := " "

SM0->(DBSelectArea("SM0"))
SM0->(DBSetOrder(1))
SM0->(DBSeek(cEmpAnt+ _cCodFil))
_cRet := SM0->M0_FILIAL 

//=================================================
//Restaura integridade da SM0
//=================================================

SM0->(DBSetOrder(_aAreaSM0[2]))
SM0->(DBGoTo(_aAreaSM0[3]))

Return _cRet
