/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor   |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------
 Julio Paz | 29/12/2021 | Inclusão Rotina visualização de Legenda Workflow Bolqueio Desconto Contatual. Chamado 30177.
 Julio Paz | 17/02/2022 | Inclusão da Opção Vinculação Clientes X Tipos de Transporte no menu. Chamado 37652. 
 Julio Paz | 02/12/2022 | Desenvolver rotina para listar Cadastro de Condições de Pagamento Personalizada. Chamado 41566
 Julio Paz | 01/10/2024 | Desenvolver rotian para replicar razão social cliente para as demais lojas. Chamado 48659. 
===============================================================================================================================
 Analista     - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
======================================================================================================================================================================================================
 Jerry        - Alex WALLAUER - 16/04/25 - 05/08/25 - 37652   - Ajuste para poder chamar pelo usuario / privilegios no cadastro de clientes.
 Guilherme    - Igor Melgaço  - 12/09/25 - 12/09/25 - 51815   - Ajuste para poder chamar privilegios do AOMS131.
======================================================================================================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MA030ROT
Autor-------------: Julio de Paula Paz
Data da Criacao---: 03/01/2019
===============================================================================================================================
Descrição---------: Ponto de entrada para inclusão de opções de menu, no MBrowse do cadastro de clientes. Permite a inclusão de
                    opções de menu no array aRotina do cadastro de clientes.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: _aRot = Array com as opções de menu a serem adicinadas no array aRotina do cadastro de clientes.
===============================================================================================================================
*/
User Function MA030ROT()
 Local _aRot := {}

 aAdd(_aRot, {"Clientes x Tipos Transportes"   ,"U_AOMS131"     , 0 , 4 ,0  , NIL})
 aAdd(_aRot, {"WF Lib.Clientes"                ,"U_MOMS041"     , 0 , 4 ,0  , NIL})
 aAdd(_aRot, {"Listagem Cond.Pagto"            ,"U_ROMS072"     , 0 , 4 ,0  , NIL})
 aAdd(_aRot, {"Atualiza Nome/Razão Soc.Cliente","U_CRM980RP"    , 0 , 4 ,0  , NIL})
 aAdd(_aRot, {"Legenda"                        ,"U_MA030LEG()"  , 0 , 4 ,0  , NIL})
   
 If FWIsInCallStack("CFGA530") // Trecho para conceder acesso ao Fonte MATA030 através de privilegios do configurador 
    aAdd( _aRot, { "AOMS131 - Pesquisar" ,"AxPesqui"    , 0, 1, 0, NIL } )
    aAdd( _aRot, { "AOMS131 - Visualizar","AxVisual"    , 0, 2, 0, NIL } )
    aAdd( _aRot, { "AOMS131 - Incluir"   ,"U_AOMS131I()", 0, 3, 0, NIL } )
    aAdd( _aRot, { "AOMS131 - Excluir"   ,"U_AOMS131E()", 0, 5, 0, NIL } )
 EndIf

Return _aRot

/*
===============================================================================================================================
Programa----------: MA030LEG()
Autor-------------: Julio de Paula Paz
Data--------------: 23/12/2021
===============================================================================================================================
Descrição---------: Função utilizada para exibir a legenda
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MA030LEG()
aLegenda :=	{	{"BR_VERDE"		, "Ativo"	},;
					{"BR_VERMELHO"	, "Inativo"	},;
				   {"BR_CINZA"	   , "Bloq. Validação Desc Contratual"	} }

BrwLegenda("Status Cadastro de Clientes.","Legenda",aLegenda)

Return

