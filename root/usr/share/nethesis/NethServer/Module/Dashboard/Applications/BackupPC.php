<?php
namespace NethServer\Module\Dashboard\Applications;

/**
 * BackupPC web interface
 *
 * @author stephane de labrusse
 */
class BackupPC extends \Nethgui\Module\AbstractModule implements \NethServer\Module\Dashboard\Interfaces\ApplicationInterface
{

    public function getName()
    {
        return "BackupPC";
    }

    public function getInfo()
    {
         $host = explode(':',$_SERVER['HTTP_HOST']);
         return array(
            'BackupPC' => "https://".$host[0]."/BackupPC",
            'Cygwin' => "https://".$host[0]."/cygwin"
         );
    }
}



