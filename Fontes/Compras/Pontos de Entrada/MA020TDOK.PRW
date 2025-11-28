/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |30/05/2022| Chamado 40048. Validação de caracteres inválidos. 
Alex Wallauer |17/01/2023| Chamado 42562. Nova validação do campo novo A2_I_LJTRN. 
Julio Paz     |04/09/2023| Chamado 44731. Alterar rotina para permitir alterar o campo Averba carga(A2_I_AVERB) sempre.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MA020TDOK
Autor-------------: Julio de Paula Paz
Data da Criacao---: 18/09/2020
Descrição---------: Ponto de Entrada que Valida a inclusão e alteração do cadastro de Fornecedores.
Parametros--------: Nenhum
Retorno-----------: _lRet = .T. = Validação Ok.
                          = .F. = Erros na validação.
===============================================================================================================================
*/
User Function MA020TDOK

Local _lRet       := .T.

If Altera .Or. Inclui
   _nSalvaRec:=SA2->(RECNO())
   If _lRet .And. SA2->(FIELDPOS("A2_I_LJTRN")) <> 0 .And. M->A2_I_LJTRN = "S" .And. SA2->(DBSeek(xFilial()+M->A2_COD))
      While SA2->(!Eof()) .And. xFilial("SA2")+M->A2_COD = SA2->A2_FILIAL+SA2->A2_COD
         If SA2->A2_MSBLQL = '1'       .OR.;//Ignora o bloqueados
            SA2->A2_LOJA == M->A2_LOJA .OR.;//Ignora a mesma loja na alteracao
            SA2->A2_EST <> M->A2_EST        //Ignora UF diferente
            SA2->(DBSkip())
            Loop
         EndIf
         If SA2->A2_I_LJTRN = "S"
            U_ITMsg( 'Já existe outro CNPJ marcado para troca nota nesta UF, loja: '+ SA2->A2_LOJA,"Atenção",;
                     "Desmarque a loja "+ SA2->A2_LOJA+ " antes de habilitar este CNPJ",1,,,.T.)
            _lRet := .F.
            Exit
         EndIf      
         SA2->(DBSkip())
      EndDo
   EndIf
   SA2->(DBGoTo(_nSalvaRec))

   If _lRet .And. !Empty(AllTrim(M->A2_NOME))
      _lRet := U_CRMA980VCP(M->A2_NOME   ,"A2_NOME")
   EndIf

   If _lRet .And. !Empty(AllTrim(M->A2_NREDUZ))
      _lRet := U_CRMA980VCP(M->A2_NREDUZ   ,"A2_NREDUZ")
   EndIf

   If _lRet .And. !Empty(AllTrim(M->A2_END))
      _lRet := U_CRMA980VCP(M->A2_END   ,"A2_END")
   EndIf

   If _lRet .And. !Empty(AllTrim(M->A2_BAIRRO))
      _lRet := U_CRMA980VCP(M->A2_BAIRRO   ,"A2_BAIRRO")
   EndIf

   If _lRet .And. !Empty(AllTrim(M->A2_COMPLEM))
      _lRet := U_CRMA980VCP(M->A2_COMPLEM   ,"A2_COMPLEM")
   EndIf

   If _lRet .And. !Empty(AllTrim(M->A2_ENDCOMP))
      _lRet := U_CRMA980VCP(M->A2_ENDCOMP   ,"A2_ENDCOMP")
   EndIf

   If _lRet .And. !Empty(AllTrim(M->cA2_CONTATO))
      _lRet := U_CRMA980VCP(M->cA2_CONTATO   ,"cA2_CONTATO")
   EndIf

EndIf

Return _lRet
