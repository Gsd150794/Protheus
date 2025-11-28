/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |25/05/2023| Chamado 43893. Ajustes no filtro para o Pedido 05 aparecer sempre.
Alex Wallauer |11/06/2024| Chamado 47499. Jerry. Correção do filtro de pedidos triangulares que não estava filtrando. 
Lucas Borges  |17/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
==============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: M460QRY
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 23/04/2010 
Descrição---------: Ponto de Entrada para filtrar os dados antes da montagem MARKBROWSE no faturamento de documentos
					(Modificações nesse PE devem ser replicadas no M460FIL)
Parametros--------: ParamIXB -[1] - filtro sql já montado pelo padrão
Retorno-----------: _cQuery- filtro a ser aplicado via filbrowse em SQL
===============================================================================================================================
*/
User Function M460QRY()     

Local _cQuery:=  ParamIXB[1]
Local _cFilVlPed := SuperGetMV('IT_FILVLPD',.T.,"")

//Faturamento por Pedido
If Upper(AllTrim(FUNNAME())) == 'MATA460A'  
  	U_M460CargaTriangular(@_cQuery,"")
	_cQuery+= " AND SC9.C9_CARGA = ' ' AND EXISTS (SELECT 'Y' FROM " + Retsqlname("SC5") +;
	                                                " SC5T WHERE SC5T.D_E_L_E_T_ = ' '  AND SC5T.C5_FILIAL = SC9.C9_FILIAL AND SC5T.C5_NUM = SC9.C9_PEDIDO AND (C5_I_TRCNF <> 'S' OR C5_I_OPER = '05'))"      
//Faturamento por Carga
Else
	_cQuery+= " AND SC9.C9_CARGA <> ' ' AND  (SELECT DAKT.DAK_I_PREC FROM " + Retsqlname("DAK") + " DAKT WHERE DAKT.D_E_L_E_T_ = ' '  AND DAKT.DAK_FILIAL = SC9.C9_FILIAL AND DAKT.DAK_COD = SC9.C9_CARGA) <> '1'"    
	If xFilial("DAK") $ _cFilVlPed // A filial faz parte da rotina de Vale pedagiro.
       
	   _cQuery += " AND  (SELECT DAKY.DAK_I_NRVP FROM " + Retsqlname("DAK") + " DAKY WHERE DAKY.D_E_L_E_T_ = ' ' AND DAKY.DAK_FILIAL = SC9.C9_FILIAL AND DAKY.DAK_COD = SC9.C9_CARGA) <> ' ' "    
	EndIf 
EndIf

Return _cQuery

/*
===============================================================================================================================
Programa----------: M460CargaTriangular(_cQuery,_cFiltro)     
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 23/04/2010 
===============================================================================================================================
Descrição---------: Função para buscar os pedidos triangular da carga inidicada no MV_PAR19
===============================================================================================================================
Parametros--------: _cQuery: do filtro do SQL / _cFiltro: do filtro ADPL
===============================================================================================================================
Retorno-----------: .T.
===============================================================================================================================
*/
User Function  M460CargaTriangular(_cQuery,_cFiltro)      

Local _cCargaRemessa  := MV_PAR19//DOC CHAMADO 28114 - parametro custumizado no pergunte padrão
Local _cOperTriangular:= ""
Local _cOperFat       := ""
Local _cOperRemessa   := ""
Local _cSPedidosVendas:= ""//SQL
Local _cAPedidosVendas:= ""//ADVPL

//O Type não pode ser usado em variavel Local tem que ser direto na vairavel Private 
If Type("MV_PAR19") == "C" .And. !Empty(_cCargaRemessa) //Testa tipo pois passa após o ínicio do faturamento com MV_PAR alterado
	
	_cOperTriangular:= AllTrim(SuperGetMV("IT_OPERTRI",.F.,"05,42"))// Tipos de operações da operação trigular
	_cOperFat       := LEFT(_cOperTriangular,2) //05
	_cOperRemessa   := RIGHT(_cOperTriangular,2)//42
	SC5->(DBSetOrder(1))
	DBSelectArea("DAI")
	DAI->(DBSetOrder(1)) //DAI_FILIAL+DAI_COD+DAI_SEQCAR+DAI_SEQUEN+DAI_PEDIDO
	If DAI->(DBSeek(xFilial("DAI")+_cCargaRemessa))
		
		While DAI->(!Eof()) .And. ;
			     DAI->DAI_FILIAL = xFilial("DAI") .And. DAI->DAI_COD = _cCargaRemessa
			
			If SC5->(DBSeek(xFilial("SC9")+DAI->DAI_PEDIDO)) .And. SC5->C5_I_OPER = _cOperRemessa //42
				_cPedVenda:=SC5->C5_I_PVFAT
				If SC5->(DBSeek(xFilial("SC9")+_cPedVenda)) .And. SC5->C5_I_OPER = _cOperFat//05
					_cSPedidosVendas+="'"+SC5->C5_NUM+"',"
					_cAPedidosVendas+=SC5->C5_NUM+"/"
				EndIf
			EndIf
			
			DAI->(DBSkip())
		EndDo
		
	EndIf
	If !Empty(_cSPedidosVendas)  .And. !Empty(_cAPedidosVendas)

        //MSSQL
		_cSPedidosVendas:=LEFT(_cSPedidosVendas,Len(_cSPedidosVendas)-1)
		_cQuery += " AND SC9.C9_PEDIDO IN ("+_cSPedidosVendas+")"

        //ADVPL
		_cAPedidosVendas:=LEFT(_cAPedidosVendas,Len(_cAPedidosVendas)-1)
		_cFiltro+=" C9_PEDIDO $ '"+_cAPedidosVendas+"' .And. "

	ElseIf !Empty(_cQuery)
		U_ITMsg("Carga "+_cCargaRemessa+" não possui Pedidos de Remessa",'Atenção!',"Selecione uma carga que possua Pedidos de Remessa",1)
		Return .F.
	EndIf
EndIf

Return .T.
