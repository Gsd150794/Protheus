#include 'Protheus.ch'
  
/*
===============================================================================================================================
Programa----------: PCTITQRY
Autor-------------: Igor Melgaço
Data da Criacao---: 26/09/2025
Descrição---------: O ponto de entrada PCTITQRY permite informar uma query personalizada para listagem de títulos no Portal do Cliente. Chamado 52267
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function PCTITQRY() As Character
   Local cOriginQry := Paramixb[1] As Array
   Local cStartQry  := "" As Character
   Local cCustomQry := "" As Character
   Local cEndQry    := "" As Character
   Local cNewQuery  := "" As Character

   // Guarda a parte de inicio da query
   cStartQry := Substr(cOriginQry, 1, AT("ORDER BY", cOriginQry) -1 )

   // Logica para customização da query (Condicional WHERE)
   cCustomQry := " AND SE1.E1_NUMBCO <> ' ' AND SE1.E1_TIPO NOT IN ('NDC')"

   // Guarda a parte final da query
   cEndQry := Substr(cOriginQry, AT("ORDER BY", cOriginQry))

   // Aplica a parte customizada na query principal
   cNewQuery := cStartQry + cCustomQry + cEndQry

Return cNewQuery
