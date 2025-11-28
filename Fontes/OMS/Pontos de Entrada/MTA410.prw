#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MTA410
Autor-------------: Alexandre Villar
Data da Criacao---: 05/01/2015
===============================================================================================================================
Descrição---------: Ponto de entrada para preencher o conteúdo dos campos customizados durante a validação total do modelo
===============================================================================================================================
Uso---------------: Italac
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: .T. - Compatibilidade com a utilização do ponto de entrada para prosseguir com o processamento
===============================================================================================================================
Usuario-----------: 
===============================================================================================================================
Setor-------------: OMS - Pedido de Vendas
===============================================================================================================================
                                    ATUALIZACOES SOFRIDAS DESDE A CONSTRUÇAO INICIAL
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           |
-------------------------------------------------------------------------------------------------------------------------------
                  |            |                                                                                              |
===============================================================================================================================
*/

User Function MTA410()

If M->C5_TIPO $ 'D/B'
	
	DBSelectArea('SA2')
	SA2->( DBSetOrder(1) )
	If SA2->( DBSeek( xFilial('SA2') + M->C5_CLIENTE + M->C5_LOJACLI ) )
	
		M->C5_I_NOME	:= SA2->A2_NOME
		M->C5_I_FANTA	:= SA2->A2_NREDUZ
		M->C5_I_EST		:= SA2->A2_EST
		M->C5_I_CMUN	:= SA2->A2_CODMUN
		M->C5_I_MUN		:= SA2->A2_MUN
		M->C5_I_CEP		:= SA2->A2_CEP
		M->C5_I_END		:= SA2->A2_END
		M->C5_I_BAIRR	:= SA2->A2_BAIRRO
		M->C5_I_DDD		:= SA2->A2_DDD
		M->C5_I_TEL		:= SA2->A2_TEL
		
	EndIf
	
Else

	DBSelectArea('SA1')
	SA1->( DBSetOrder(1) )
	If SA1->( DBSeek( xFilial('SA1') + M->C5_CLIENTE + M->C5_LOJACLI ) )
	
		M->C5_I_NOME	:= SA1->A1_NOME
		M->C5_I_FANTA	:= SA1->A1_NREDUZ
		M->C5_I_EST		:= SA1->A1_EST
		M->C5_I_CMUN	:= SA1->A1_COD_MUN
		M->C5_I_MUN		:= SA1->A1_MUN
		M->C5_I_CEP		:= SA1->A1_CEP
		M->C5_I_END		:= SA1->A1_END
		M->C5_I_BAIRR	:= SA1->A1_BAIRRO
		M->C5_I_DDD		:= SA1->A1_DDD
		M->C5_I_TEL		:= SA1->A1_TEL
		M->C5_I_GRPVE	:= SA1->A1_GRPVEN
		M->C5_I_NOMRD	:= Posicione( 'ACY' , 1 , xFilial('ACY') + SA1->A1_GRPVEN , 'ACY_DESCRI' )
		
	EndIf

EndIf

M->C5_I_DESCO := Posicione( 'SE4' , 1 , xFilial('SE4') + M->C5_CONDPAG , 'E4_DESCRI' )

Return(.T.)
