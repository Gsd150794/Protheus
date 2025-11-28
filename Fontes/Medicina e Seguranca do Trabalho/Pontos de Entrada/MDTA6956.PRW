/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |10/04/2018| Chamado 23960. Realização de ajustes nas rotinas de entrega e devolução de EPI, para impressão correta
              |          | dos comprovantes.
Jonathan      |16/07/2020| Chamado 33416. Ajuste da impressão do recibo de entrega.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MDTA6956
Autor-------------: Julio de Paula Paz
Data da Criacao---: 09/11/2017
Descrição---------: Ponto de entrada da criação do menu principal da rotinade EPIs. Criação do array aRotina da função MenuDef.
                    Chamado 23960. 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MDTA6956()

Local _aRot := {}

Public _l655CTR := .F.

Begin Sequence

   aAdd(_aRot,{ "EPIs Italac", "U_MDTA695V", 0 , 4}	)

End Sequence

Return _aRot 

/*
===============================================================================================================================
Programa----------: MDTA695V
Autor-------------: Julio de Paula Paz
Data da Criacao---: 09/11/2017
Descrição---------: Esta função chama a função padrão de manutenção de EPIs e em seguida chama a rotina de impressão do 
                    documento Recibo de Entrega de EPIs customizado para Italac, caso exista documento a ser impresso.
Parametros--------: cAlias - Alias do arquivo
                    nReg   - Numero do registro
                    nOpcx  - Opcao selecionada no menu
                    oParent- Objeto pai onde serão criados os objetos
                    oGet   - Objeto MSGetDados passado por referencia
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MDTA695V(cAlias,nReg,nOpcx,oParent, oGetEPI )

Begin Sequence
  //=========================================================================
  // Chama rotina padrão de EPIs
  //=========================================================================
  NGFUN695(cAlias,nReg,4,oParent, oGetEPI )

  //=========================================================================
  // Chama rotina de impressão dos documentos de entrega.
  //=========================================================================
  If U_MDTA695X()
     U_MDTA695U() 
  EndIf

End Sequence

Return
