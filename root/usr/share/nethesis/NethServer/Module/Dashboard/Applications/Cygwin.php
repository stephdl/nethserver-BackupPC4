<?php
namespace NethServer\Module\Dashboard\Applications;

/**
 * BackupPC web interface
 *
 * @author stephane de labrusse
 */
class Cygwin extends \Nethgui\Module\AbstractModule implements \NethServer\Module\Dashboard\Interfaces\ApplicationInterface
{

    public function getName()
    {
        return "Cygwin";
    }

    public function getInfo()
    {
         $host = explode(':',$_SERVER['HTTP_HOST']);
         return array(
            'url' => "https://".$host[0]."/cygwin"
         );
    }
}



