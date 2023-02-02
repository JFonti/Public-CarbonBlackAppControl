# Simple File Signature interrogation v.1
# Joe Fonti  on  Aug 20, 2020
# For BAH DHS CDM

$SignedFileTypes =@(".exe", ".dll", ".sys", ".inf", ".cat")

#Directory of file to be interrogated.
$ToolDirectory = "C:\Program Files\Npcap\uninstall.exe"

ForEach ($File in Get-ChildItem -Path "$ToolDirectory" -Recurse)
{

  if ($SignedFileTypes -contains $file.Extension)
  {

    Get-AuthenticodeSignature -FilePath $file.PSPath
    Get-AuthenticodeSignature -FilePath $file.PSPath | Select-Object -ExpandProperty SignerCertificate | Select-object -Property SerialNumber, Thumbprint
    

  }
} 
