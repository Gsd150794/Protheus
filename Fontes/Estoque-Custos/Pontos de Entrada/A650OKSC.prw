/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: A650OKSC
Autor-------------: Tiago Correa Castro
Data da Criacao---: 27/10/2008
Descrição---------: Na validacao da geracao da solicitacao de compra por uma OP. Ponto de Entrada valida para que nao seja gerada
					Solicitacao de Compra para os produtos do Grupo de Materia Prima(B1_GRUPO = 0800).
Parametros--------: Nenhum
Retorno-----------: .T. ou .F.
===============================================================================================================================
*/
User Function A650OKSC()

	Local	aArea	:=	FWGetArea()
	Local	_lRet	:=	.T.   
	Local	_cProd	:=	ParamIXB[1]
    
	DBSelectArea("SB1")
	DBSetOrder(1)
	DBSeek(xFilial("SB1")+_cProd)
    
    If SB1->B1_GRUPO == "0800"
    	MsgAlert("E necessario a realizacao de uma entrada ou desmontagem para o Produto: "+AllTrim(SB1->B1_COD)+ " - " +AllTrim(SB1->B1_I_DESCD)+;
    			 " da OP: "+ParamIXB[3]+". Para esse produto nao e possivel a geracao de Solicitacao de Compra.","Solicitacao de Compra Cancelada") 
	   	_lRet	:=	.F.  
    EndIf 

	FWRestArea(aArea)

Return (_lRet)
