/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor   |    Data    |                                             Motivo                                           
------------------------------------------------------------------------------------------------------------------------
 Julio Paz | 29/12/2021 | Inclusão de rotina para visualizar legendas dos cadastro clientes. Chamado 30177.
 Julio Paz | 17/02/2022 | Inclusão da Opção Vinculação Clientes X Tipos de Transporte no menu. Chamado 37652. 
 Julio Paz | 02/12/2022 | Desenvolver rotina para listar Cadastro de Condições de Pagamento Personalizada. Chamado 41566
 Julio Paz | 01/10/2024 | Desenvolver rotian para replicar razão social cliente para as demais lojas. Chamado 48659.
======================================================================================================================================================================================================
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
#Include "FWMVCDEF.CH"

/*
===============================================================================================================================
Programa--------: CRM980MDef
Autor-----------: Igor Melgaço
Data da Criacao-: 24/08/2021
===============================================================================================================================
Descrição---------: Ponto de entrada para inclusão de opções de menu, no MBrowse do cadastro de clientes. Permite a inclusão de
                    opções de menu no array aRotina do cadastro de clientes. Substitui o ponto MA030ROT.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: _aRot = Array com as opções de menu a serem adicinadas no array aRotina do cadastro de clientes.
===============================================================================================================================
*/
User Function CRM980MDef()
 Local aRotina := {}
//----------------------------------------------------------------------------------------------------------
// [n][1] - Nome da Funcionalidade
// [n][2] - Função de Usuário
// [n][3] - Operação (1-Pesquisa; 2-Visualização; 3-InclusÃ£o; 4-Alteração; 5-ExclusÃ£o)
// [n][4] - Acesso relacionado a rotina, se esta posição nÃ£o For informada nenhum acesso será validado
//----------------------------------------------------------------------------------------------------------

 aAdd(aRotina,{"Clientes x Tipos Transportes"   ,"U_AOMS131"     ,MODEL_OPERATION_UPDATE,0})
 aAdd(aRotina,{"WF Lib.Clientes"                ,"U_MOMS041"     ,MODEL_OPERATION_VIEW  ,0})
 aAdd(aRotina,{"Listagem Cond.Pagto"            ,"U_ROMS072"     ,MODEL_OPERATION_VIEW  ,0})
 aAdd(aRotina,{"Atualiza Nome/Razão Soc.Cliente","U_CRM980RP"    ,MODEL_OPERATION_VIEW  ,0})
 aAdd(aRotina,{"Legenda"                        ,"U_CRM980LEG()" ,MODEL_OPERATION_VIEW  ,0})

 If FWIsInCallStack("CFGA530") // Trecho para conceder acesso ao Fonte MATA030 através de privilegios do configurador 
    aAdd( aRotina, { "AOMS131 MVC - Pesquisar" ,"AxPesqui"     , 1 ,0})
    aAdd( aRotina, { "AOMS131 MVC - Visualizar","AxVisual"     , 2 ,0})
    aAdd( aRotina, { "AOMS131 MVC - Incluir"   ,"U_AOMS131I()" , 3 ,0})
    aAdd( aRotina, { "AOMS131 MVC - Excluir"   ,"U_AOMS131E()" , 5 ,0})
 EndIf

Return( aRotina )

/*
===============================================================================================================================
Programa----------: CRM980LEG()
Autor-------------: Julio de Paula Paz
Data--------------: 23/12/2021
===============================================================================================================================
Descrição---------: Função utilizada para exibir a legenda.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function CRM980LEG()
aLegenda :=	{	{"BR_VERDE"		, "Ativo"	},;
					{"BR_VERMELHO"	, "Inativo"	},;
				   {"BR_CINZA"	   , "Bloq. Validação Desc Contratual"	} }

BrwLegenda("Status Cadastro de Clientes.","Legenda",aLegenda)

Return 

/*
===============================================================================================================================
Programa----------: CRM980RP
Autor-------------: Julio de Paula Paz
Data--------------: 01/10/2024
===============================================================================================================================
Descrição---------: Replica o nome/razão social do cliente posicionado, para as demais lojas do cliente.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function CRM980RP()
Local _nRegAtu := SA1->(Recno())
Local _cNome   := AllTrim(SA1->A1_NOME)
Local _cCodigo := SA1->A1_COD
Local _aClientes := {} 
Local _nI 

Begin Sequence 
   If ! U_ITMsg("Confirma a atualização do Nome/Razão Social das demais lojas deste cliente, com o nome: " + AllTrim(_cNome + " ?"),"Atenção" , , ,2, 2)
      Break 
   EndIf

   SA1->(DBSetOrder(1))
   SA1->(MsSeek(xFilial("SA1")+_cCodigo))

   //==================================================================================
   // Grava o recno da tabela SA1 em um Array, para posterior gravação dos dados.
   // Já houve chamados de correção em que o ponteiro de registro se perde,
   // quando se tem um While e um RecLock na mesma tabela.
   //==================================================================================
   While ! SA1->(Eof()) .And. SA1->A1_COD == _cCodigo
      If _nRegAtu <> SA1->(Recno())
         aAdd(_aClientes,SA1->(Recno()))
      EndIf

      SA1->(DBSkip())
   EndDo 

   For _nI := 1 To Len(_aClientes)
       
       SA1->(DBGoTo(_aClientes[_nI ]))

       If ! (AllTrim(SA1->A1_NOME) == _cNome)
          SA1->(DBGoTo(_aClientes[_nI ]))
          SA1->(RecLock("SA1",.F.))
          SA1->A1_NOME := _cNome
          SA1->(MSUnLock())
       EndIf 
   Next 

End Sequence

SA1->(DBGoTo(_nRegAtu))

U_ITMsg("A atualização do nome/razão social do cliente foi concluida.","Atenção",,1)

Return


