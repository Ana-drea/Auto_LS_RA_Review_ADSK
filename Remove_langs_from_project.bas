'Removes all languages from the MUI project except that match 3 letter code in LPU filename.
'E.g. when run for deu_myfile_res.lpu, all languages other than "deu" will be removed from LPU.

Sub Main
  Dim prj As PslProject
  Dim pattern As String
  Dim patternCheck As Boolean
  Set prj = PSL.ActiveProject

  pattern = Left(prj.Name, 3)
  PSL.Output prj.Name
  PSL.Output pattern

  If prj Is Nothing Then
  PSL.Output "No active project found."
  Else
  	PSL.Output pattern
    For Each lang In prj.Languages
    patternCheck = Str(lang.LangCode) Like pattern
    If patternCheck = False Then
		PSL.Output "Removing" & lang.LangCode
		prj.Languages.Remove(lang)
    End If
    Next lang
  End If

End Sub



