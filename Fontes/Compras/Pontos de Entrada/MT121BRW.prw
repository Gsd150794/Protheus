/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |07/04/2022| Chamado 38650. Criada a rotina de Reenvio DE E-mail DE Avaliacao. 
Igor Melgaço  |22/07/2022| Chamado 40694. Inclusão das chamadas para a rotina de alteração de investimento.
Julio Paz     |27/02/2025| Chamado 49391. Desenvolvimento de Rotina para alteração da Data de Entrega do Pedido de Compras.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT121BRW
Autor-------------: Alexandre Villar
Data da Criacao---: 03/09/2015                                    .
Descrição---------: P.E. para incluir opções no menu da tela de pedidos de compras
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MT121BRW

aAdd( aRotina , { "Alt.Dt.Fat.IT"		     , "U_ACOM004"		, 0 , 4 , 0 , Nil } )
aAdd( aRotina , { "Alt.Dt.Fat PC"		     , "U_ACOM008(.F.)"	, 0 , 4 , 0 , Nil } )  
aAdd( aRotina , { "Alt.Loja Forn. PC"	     , "U_ACOM008(.T.)"	, 0 , 4 , 0 , Nil } )  
aAdd( aRotina , { "Titulos Prev."		     , "U_CCOM002(1)"	, 0 , 4 , 0 , Nil } )
aAdd( aRotina , { "Ajustes do LEITE"	     , "U_AGLT019()" 	, 0 , 2			  } )
aAdd( aRotina , { "Agendamento LEITE"	     , "U_AGLT0192(.T.)", 0 , 2			  } )
aAdd( aRotina , { "Liber. Gestor Comp"	     , "U_ACOM011()" 	, 0 , 4 , 0 , Nil } )
aAdd( aRotina , { "E-mail Fornecedor"	     , "U_RCOM002()" 	, 0 , 4 , 0 , Nil } )
aAdd( aRotina , { "Reenvio Workflow"	     , "U_MCOM004E()"	, 0 , 4 , 0 , Nil } )
aAdd( aRotina , { "Reenvio E-mail Avaliacao" , "U_MCOM04RA()"	, 0 , 4 , 0 , Nil } )
aAdd( aRotina , { "L&ista Liberados"	     , "U_MCOM001()"	, 0 , 4 , 0 , Nil } )
aAdd( aRotina , { "Monitor PC"			     , "U_ACOM017P()"	, 0 , 4 , 0 , Nil } )
aAdd( aRotina , { "Alt Servico"			     , "U_ACOM018()"	, 0 , 4 , 0 , Nil } )
aAdd( aRotina , { "Alt Apl.Direta"		     , "U_ACOM035()"	, 0 , 4 , 0 , Nil } )
aAdd( aRotina , { "Reenvio E-mail"		     , "FWMsgRun(,{||U_MCOM004F(SC7->C7_FILIAL, SC7->C7_NUM, 'Reenvio', )},,'Aguarde... Reenviando E-mail...')"	, 0 , 4 , 0 , Nil } )
aAdd( aRotina , { "Impr - Almox"		     , "U_RCOM018()"	, 0 , 4 , 0 , Nil } )
aAdd( aRotina , { "Impr - Romaneio NF"	     , "U_RCOM019()"	, 0 , 4 , 0 , Nil } )
aAdd( aRotina , { 'Alter.Cod.Invest.'        , 'U_ACOM039()'    , 0 , 4 , 0 , Nil } )
aAdd( aRotina , { 'Alter.Cod.Invest. em lote', 'U_ACOM039(.T.)' , 0 , 4 , 0 , Nil } )
aAdd( aRotina , { 'Altera Data de Entrega'   , 'U_ACOM042()'    , 0 , 4 , 0 , Nil } )

Return
