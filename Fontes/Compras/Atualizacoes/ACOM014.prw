/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |17/07/2017| Chamado 20777. Virada de versão da P11 para a versão P12. Ajustes no fonte para a versão P12
Alex Wallauer |25/09/2019| Chamado 30673. Ajustes para o novo nivel 5 dos produtos.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: ACOM014
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 26/08/2008
Descrição---------: Retorno de Inicializador Padrao e Inicializador do Browse
                    Rotina chamada na validacao de Inicializador Padrao(X3_RELACAO) e no Inicializador de Browse (X3_INIBRW)  
                    dos campos: SB1->B1_I_NOMGR								                                               
                                SB1->B1_I_DESN2						                                   						
                                SB1->B1_I_DESN3						                                   						
                                SB1->B1_I_DESN4						                                   						
                                SBZ->BZ_COD							                                   						
                                SB1->B1_I_DESTP
Parametros--------: 1=Retorna informacao para preenchimento do Inicializador Padrao(X3_RELACAO) do campo SB1->B1_I_NOMGR        
                    2=Retorna informacao para preenchimento do Inicializador de Browse (X3_INIBRW) do campo SB1->B1_I_NOMGR   	
                    3=Retorna informacao para preenchimento do Inicializador Padrao(X3_RELACAO) do campo SB1->B1_I_DESN2        
                    4=Retorna informacao para preenchimento do Inicializador de Browse (X3_INIBRW) do campo SB1->B1_I_DESN2   	
                    5=Retorna informacao para preenchimento do Inicializador Padrao(X3_RELACAO) do campo SB1->B1_I_DESN3        
                    6=Retorna informacao para preenchimento do Inicializador de Browse (X3_INIBRW) do campo SB1->B1_I_DESN3   	
                    7=Retorna informacao para preenchimento do Inicializador Padrao(X3_RELACAO) do campo SB1->B1_I_DESN4        
                    8=Retorna informacao para preenchimento do Inicializador de Browse (X3_INIBRW) do campo SB1->B1_I_DESN4   	
                    9= Não utilizado.	        
                    10=Não utilizado.		   
                    11=Retorna informacao para preenchimento do Inicializador Padrao(X3_RELACAO) do campo SB1->B1_I_DESTP        
                    12=Retorna informacao para preenchimento do Inicializador de Browse (X3_INIBRW) do campo SB1->B1_I_DESTP	   
Retorno-----------: Retorna o nome para ser preenchido no Inicializador Padrao(X3_RELACAO) e Inicializador de Browse 
                    (X3_INIBRW).
===============================================================================================================================
*/
User Function ACOM014(_nOpc)

	Local aArea 	:= FWGetArea()
	Local cRet		:=	""     
	
	If _nOpc == 1 .And. !inclui 
		cRet	:=	AllTrim(Posicione("SBM",1,xFilial("SBM")+SB1->B1_GRUPO,"BM_DESC"))
	ElseIf _nOpc == 2
		cRet	:=	AllTrim(Posicione("SBM",1,xFilial("SBM")+SB1->B1_GRUPO,"BM_DESC"))

	ElseIf _nOpc == 3 .And. !inclui
		cRet	:=	AllTrim(Posicione("ZA1",1,xFilial("ZA1")+SB1->B1_GRUPO+SB1->B1_I_NIV2,"ZA1_DESCRI"))
	ElseIf _nOpc == 4
		cRet	:=	AllTrim(Posicione("ZA1",1,xFilial("ZA1")+SB1->B1_GRUPO+SB1->B1_I_NIV2,"ZA1_DESCRI"))

	ElseIf _nOpc == 5 .And. !inclui
		cRet	:=	AllTrim(Posicione("ZA2",1,xFilial("ZA2")+SB1->B1_I_NIV3,"ZA2_DESCRI"))
	ElseIf _nOpc == 6
		cRet	:=	AllTrim(Posicione("ZA2",1,xFilial("ZA2")+SB1->B1_I_NIV3,"ZA2_DESCRI"))

	ElseIf _nOpc == 7 .And. !inclui
		cRet	:=	AllTrim(Posicione("ZA3",1,xFilial("ZA3")+SB1->B1_I_NIV4,"ZA3_DESCRI"))
	ElseIf _nOpc == 8
		cRet	:=	AllTrim(Posicione("ZA3",1,xFilial("ZA3")+SB1->B1_I_NIV4,"ZA3_DESCRI"))

	ElseIf _nOpc == 11 .And. !inclui
		cRet	:=	AllTrim(Posicione("SX5",1,xFilial("SX5")+"02"+AllTrim(SB1->B1_TIPO),"X5_DESCRI"))
	ElseIf _nOpc == 12
		cRet	:=	AllTrim(Posicione("SX5",1,xFilial("SX5")+"02"+AllTrim(SB1->B1_TIPO),"X5_DESCRI"))

	ElseIf _nOpc == 13 .And. !inclui
		cRet	:=	AllTrim(Posicione("ZA0",1,xFilial("ZA0")+SB1->B1_I_NIV5,"ZA0_DESCRI"))
	ElseIf _nOpc == 14
		cRet	:=	AllTrim(Posicione("ZA0",1,xFilial("ZA0")+SB1->B1_I_NIV5,"ZA0_DESCRI"))
	EndIf
	
   // Grava log da rotina de Inicializador Padrão e Inicilizador de 
   // Browser.
   U_ITLOGACS('ACOM014')
	
   FWRestArea(aArea)

Return (cRet)
