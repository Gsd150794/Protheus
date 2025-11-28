/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |03/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Igor Melgaço  |19/07/2022| Chamado 40620. Inclusão das chamadas para a rotina de alteração de investimento.
Igor Melgaço  |22/07/2022| Chamado 40694. Retirada das chamadas para a rotina de alteração de investimento.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT120BRW
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 07/04/2009
Descrição---------: Ponto de entrada para criar botao no browse do pedido de compra
					Localização: Function MATA120 - Função do Pedido de Compras e Autorização de Entrega.
					Em que Ponto: Após a montagem do Filtro da tabela SC7 e antes da execução da Mbrowse do PC, utilizado para 
					adicionar mais opções no aRotina.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MT120BRW

//	Alterar parametro MV_PCOMPRA para o relatorio personalizado
aAdd( aRotina, { 'Transport.', 'U_ACOM031()', 0, 4 } )// Amarrar/Alterar transportadora

Return
