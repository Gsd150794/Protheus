/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |25/03/2022| Chamado 39566. Desenvolvimento de uma nova integração para receber informações de Vale pedágio.  
Alex Wallauer |25/05/2023| Chamado 43893. Ajustes no filtro para o Pedido 05 aparecer sempre.
Lucas Borges  |17/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: M460FIL
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 23/04/2010 
Descrição---------: Ponto de Entrada para filtrar os dados antes da montagem MARKBROWSE no faturamento de documentos
					(Modificações nesse PE devem ser replicadas no M460QRY)
Parametros--------: Nenhum
Retorno-----------: _cFiltro - filtro a ser aplicado via filbrowse em advpl
===============================================================================================================================
*/
User Function M460FIL
   
Local _cFiltro:= ""

_cFilVlPed := SuperGetMV('IT_FILVLPD',.F.,"")

//Faturamento por Pedido
If Upper(AllTrim(FUNNAME())) == 'MATA460A'  
  	U_M460CargaTriangular("",@_cFiltro)//Essa função esta no M460QRY.PRW
	_cFiltro+= " C9_CARGA == '      ' .And. ( Posicione('SC5',1,C9_FILIAL+C9_PEDIDO,'C5_I_TRCNF') <> 'S' .Or. Posicione('SC5',1,C9_FILIAL+C9_PEDIDO,'C5_I_OPER') = '05' ) "
//Faturamento por Carga
Else
	_cFiltro+= " C9_CARGA != '      ' .And. DAK_I_PREC != '1' " 
    If xFilial("DAK") $  _cFilVlPed // Rotina possui controle de vale pedágio.
       _cFiltro+= " .And. DAK_I_NRVP <> ' ' "
	EndIf 
EndIf

Return _cFiltro
