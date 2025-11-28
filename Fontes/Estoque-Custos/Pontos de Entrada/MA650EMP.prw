/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |27/10/2015| Chamado 12006. Adicionada gravação do D4_I_POR  a partir do acols
Alex Wallauer |05/09/2019| Chamado 27300. Ajustes na gravação dos campos D4_I_QTORI e D4_I_QORSG
===============================================================================================================================
*/

#Include "TOTVS.ch"
                     
/*
===============================================================================================================================
Programa----------: MA650EMP
Autor-------------: Andre Lisboa
Data da Criacao---: 30/06/2015
Descrição---------: Ponto de entrada para ajustar empenhos após gravação do sd4 na gravação de op 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MA650EMP()

Local _nPosCod   	:= aScan(aheader,{|x| AllTrim(x[2])=="G1_COMP"})
Local _nPospgor 	:= aScan(aheader,{|x| AllTrim(x[2])=="D4_I_PGOR"})
Local _nPospQTORI 	:= aScan(aheader,{|x| AllTrim(x[2])=="D4_I_QTORI"})
Local _nPospQORSG 	:= aScan(aheader,{|x| AllTrim(x[2])=="D4_I_QORSG"})
Local _nni			:= 0
//Local cFilial := SD4->D4_FILIAL //Filial
//Local cOp := SD4->D4_OP        // OP
/*
DBSelectArea("SD4")
SD4->( DBSetOrder(2) ) // D4_FILIAL+D4_OP+D4_COD
SD4->( DBSeek(cFilial+cOp) )
	
While ( (SD4->D4_FILIAL == cFilial) .And. (SD4->D4_OP == cOp) )

	RecLock("SD4",.F.)
	SD4->D4_I_QTORI 	:= SD4->D4_QUANT                  //grava quantidade original do empenho
	SD4->D4_I_QORSG 	:= SD4->D4_QTSEGUM		  //grava quantidade original do empenho na 2a. UM
	MSUnLock()
		
	SD4->( DBSkip() )
	
EndDo
*/


//Varre o acols procurando os procentuais de gordura para gravar no d4
For _nni := 1 to Len(acols)

	//posiciona d4 para gravar porcentual de gordura
	DBSelectArea("SD4")
	SD4->( DBSetOrder(2) ) // D4_FILIAL+D4_OP+D4_COD
	
	If  SD4->( DBSeek ( xFilial("SD4") + AVKEY(SC2->C2_NUM+SC2->C2_ITEM+SC2->C2_SEQUEN,"D4_OP")+acols[_nni][_nPosCod] ) )
	
		RecLock("SD4",.F.)
		
		SD4->D4_I_PGOR  := acols[_nni][_nPospgor]
	    SD4->D4_I_QTORI	:= acols[_nni][_nPospQTORI]                  //grava quantidade original do empenho
	    SD4->D4_I_QORSG	:= acols[_nni][_nPospQORSG] //grava quantidade original do empenho na 2a. UM
		
		SD4->( MSUnLock() )
		
	EndIf
	
Next


Return 
