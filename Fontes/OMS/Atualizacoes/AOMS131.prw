/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Analista     - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
======================================================================================================================================================================================================
 Jerry        - Alex WALLAUER - 21/01/25 - 05/08/25 - 37652   - Ajuste para poder chamar do U_FORMULA() pelo usuario no cadastro de clientes.
 Jerry        - Alex WALLAUER - 16/04/25 - 05/08/25 - 37652   - Ajuste para poder chamar pelo usuario / privilegios no cadastro de clientes.
=======================================================================================================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "FWMVCDef.Ch"

/*
===============================================================================================================================
Programa----------: AOMS131
Autor-------------: Julio de Paula Paz
Data da Criacao---: 05/01/2022
===============================================================================================================================
Descrição---------: Rotina de Cadastro de Cadastro Clientes x Tipo de Veiculos.
                    Esta rotina considera estar posicionada no cadastro de clientes (SA1). Chamado 37652.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS131()
Local aArea   := FWGetArea() As Array
Local _bCond  As Block
Local _cCond  As Character
//Local _aRotBack As Array

If !FWIsInCallStack("MATA030")
   Return MATA030()//CADASTRO DE CLIENTES QUANDO CHAMADA DO U_FORMULA()
EndIf

//_aRotBack := AClone(aRotina)
Private aRotina:= MenuDef() 

Private _cTitulo 
Private _oBrowse 

Begin Sequence 
   DBSelectArea("ZBB")

   _bCond := { || SA1->A1_COD = ZBB_CLIENT .And. SA1->A1_LOJA = ZBB_LOJA }
   _cCond := "SA1->A1_COD = ZBB_CLIENT .And. SA1->A1_LOJA = ZBB_LOJA"
   _cTitulo := "Clientes x Tipos de Veiculos: "+ SA1->A1_COD + "/" +SA1->A1_LOJA + "-" + SA1->A1_NOME
   
   ZBB->(DBSetFilter( _bCond , _cCond )) 


    //Instânciando FWMBrowse - Somente com dicionário de dados
    _oBrowse := FWMBrowse():New()
     
    //Setando a tabela de cadastro de Autor/Interprete
    _oBrowse:SetAlias("ZBB")
 
    //Setando a descrição da rotina
    _oBrowse:SetDescription(_cTitulo)
     
    //Ativa a Browse
    _oBrowse:Activate()

End Sequence 

//aRotina := AClone(_aRotBack)

DBSelectArea("SA1")

FWRestArea(aArea)

Return
 
/*
===============================================================================================================================
Programa----------: AOMS131P
Autor-------------: Julio de Paula Paz
Data da Criacao---: 05/01/2022
===============================================================================================================================
Descrição---------: Rotina de preenchimento de campos obrigatórios.
                    Esta rotina considera estar posicionada no cadastro de clientes (SA1).
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS131P()
 Local _cRet := SA1->A1_COD

 M->ZBB_CLIENT := SA1->A1_COD
 M->ZBB_LOJA   := SA1->A1_LOJA
 M->ZBB_NOMCLI := SA1->A1_NOME
 If DUT->(MsSeek(xFilial("DUT")+M->ZBB_TPVEIC))
    M->ZBB_PALETE := DUT->DUT_QTUNIH
 EndIf

Return _cRet 

/*
===============================================================================================================================
Programa----------: AOMS131E
Autor-------------: Julio de Paula Paz
Data da Criacao---: 05/01/2022
===============================================================================================================================
Descrição---------: Rotina de preenchimento de campos obrigatórios.
                    Esta rotina considera estar posicionada no cadastro de clientes (SA1).
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS131E()
Local _cTpVeic, _cNomeVeic 

Begin Sequence 
   _cTpVeic   := ZBB->ZBB_TPVEIC
   _cNomeVeic := AllTrim(ZBB->ZBB_NOMVEI)

   If U_ITMsg("Confirma a Exclusão do Tipo de Veiculo: " + _cTpVeic + " - " + _cNomeVeic + " ?" ,"Atenção", , ,2, 2)
      
      ZBB->(RecLock("ZBB",.F.))
      ZBB->(DbDelete())
      ZBB->(MSUnLock())
      _oBrowse:Refresh()

      U_ITMsg("Tipo de Veiculo :" + _cTpVeic + " - " + _cNomeVeic + ", excluido com sucesso!","Atenção",,1)

   EndIf 

End Sequence 

Return 

/*
===============================================================================================================================
Programa----------: AOMS131I
Autor-------------: Julio de Paula Paz
Data da Criacao---: 05/01/2022
===============================================================================================================================
Descrição---------: Rotina de inclusão dos tipos de transportes vinculados ao cadastro de clientes.
                    Esta rotina considera estar posicionada no cadastro de clientes (SA1).
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS131I()

Begin Sequence 

   AxInclui( 'ZBB', /*<nReg>*/, /*<nOpc>*/, /*<aAcho>*/, /*<cFunc>*/, /*<aCpos>*/, "U_AOMS131V()")

End Sequence 

Return 

/*
===============================================================================================================================
Programa----------: AOMS131V
Autor-------------: Julio de Paula Paz
Data da Criacao---: 05/01/2022
===============================================================================================================================
Descrição---------: Rotina de Validação do Cadastro de Cadastro Clientes x Tipo de Veiculos.
                    Esta rotina considera estar posicionada no cadastro de clientes (SA1).
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS131V(_oModel)
Local _lRet := .T.

Begin Sequence 
   
   ZBB->(DBSetOrder(1))
   If ZBB->(MsSeek(xFilial("ZBB")+SA1->A1_COD+SA1->A1_LOJA+M->ZBB_TPVEIC))
      U_ITMsg("Já existe o tipo de veiculo cadastrado para este Cliente e Loja.","Atenção",,1)
      _lRet := .F.
   EndIf 
   
End Sequence 

Return _lRet 

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Alex Wallauer
Data da Criacao---: 16/04/2025
===============================================================================================================================
Descrição---------: Rotina para criação do menu da tela principal
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: _aRotina - Array com as opções de menu
===============================================================================================================================
*/
Static Function MenuDef()
 Local aRotina2 := {}
 //If FWIsInCallStack("CFGA530") // Colocar esse If menu do primeiro Browse (CRM980MDEF.PRW (MVC) e MA030ROT.PRW) com todas as linhas abaixo 
 //   para conceder acesso ao Fonte MATA030 através de privilegios do configurador 
 aAdd(aRotina2,{ "Pesquisar"    ,"AxPesqui"                , 0, 1})
 aAdd(aRotina2,{ "Visualizar"   ,"AxVisual"                , 0, 2})
 aAdd(aRotina2,{ "Incluir"      ,"U_AOMS131I()"            , 0, 3})
 aAdd(aRotina2,{ "Excluir"      ,"U_AOMS131E()"            , 0, 5})

Return( aRotina2 )
