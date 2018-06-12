<?php
/*
 * Created on Sep 14, (c) 2006 by Marcel K�hn
 * GPL licensed, marcel@kuehns.org
 *
 * Ported nagios range checking from Nagios::Plugin::Range
 * by Doug Warner <doug@warner.fm>
 */

#Configuration

define('STATE_OK',0);
define('STATE_WARNING',1);
define('STATE_CRITICAL',2);
define('STATE_UNKNOWN',3);
define('STATE_DEPENDENT',4);

define('SNMPWALK','/usr/bin/snmpwalk');

function detectOS(){
    $arr    =   posix_uname();
    return strtolower($arr["sysname"]);
}

function verifyOS($supportedOSarray){
    $runningOS  =   detectOS();
    if(in_array($runningOS,$supportedOSarray)){
        return TRUE;
    }
    else{
        return FALSE;
    }
}

function machineName(){
    $arr    =   posix_uname();
    return strtolower($arr["nodename"]);
}

class Nagios_Plugin_Range {
    const INSIDE = 1;
    const OUTSIDE = 0;
    protected $range;
    protected $start = 0;
    protected $end = 0;
    protected $start_infinity = false;
    protected $end_infinity = false;
    protected $alert_on;

    public function __construct($range) {
        $this->range = $range;
        $this->parse_range_string($range);
    }

    public function valid() {
        return isset($this->alert_on);
    }

    public function check_range($value) {
        $false = false;
        $true = true;
        if ($this->alert_on == self::INSIDE) {
            $false = true;
            $true = false;
        }

        /* DEBUG
        echo "  R:$this->range; V:$value; S:$this->start, E:$this->end, ".
            "SI: " . ( $this->start_infinity ? 'T' : 'F') . ', ' .
            "EI: " . ( $this->end_infinity ? 'T' : 'F') . ', ' .
            "InOut: " . ( $this->alert_on == self::INSIDE ? 'I' : 'O') . '; ' .
"\n";
        */
        if (!$this->end_infinity && !$this->start_infinity ) {
            if ($this->start <= $value && $value <= $this->end) {
                return $false;
            } else {
                return $true;
            }
        }
        elseif (!$this->start_infinity && $this->end_infinity) {
            if ( $value >= $this->start ) {
                return $false;
            } else {
                return $true;
            }
        }
        elseif ($this->start_infinity && !$this->end_infinity) {
            if ($value <= $this->end) {
                return $false;
            } else {
                return $true;
            }
        }
        else {
            return $false;
        }
    }

    # Returns a N::P::Range object if the string is a conforms to a Nagios Plugin range string, otherwise null
    protected function parse_range_string($string) {
        $valid = 0;
        $alert_on = self::OUTSIDE;

        $string = preg_replace('/\s/', '', $string);

        $value = "[-+]?[\d\.]+";
        $value_re = "${value}(?:e${value})?";

        # check for valid range definition
        if ( !preg_match('/[\d~]/', $string)
            || !preg_match("/^\@?(${value_re}|~)?(:(${value_re})?)?$/", $string)) {
            echo "invalid range definition '$string'";
            exit(STATE_UNKNOWN);
        }

        if (preg_match('/^\@/', $string)) {
            $string = preg_replace('/^\@/', '', $string);
            $alert_on = self::INSIDE;
        }

         # '~:x'
        if (preg_match('/^~/', $string)) {
            $string = preg_replace('/^~/', '', $string);
            $this->start_infinity = true;
        }

        # '10:'
        if (preg_match("/^(${value_re})?:/", $string, $matches)) {
            if (!empty($matches[1])) {
                $this->set_range_start($matches[1]);
            }
            $this->end_infinity = true;  # overridden below if there's an end specified
            $string = preg_replace("/^(${value_re})?:/", '', $string);
            $valid++;
        }

        # 'x:10' or '10'
        if (preg_match("/^(${value_re})$/", $string)) {
            $this->set_range_end($string);
            $valid++;
        }
if ($valid
            && ($this->start_infinity || $this->end_infinity || $this->start <= $this->end)) {
            $this->alert_on = $alert_on;
        }
    }

    protected function set_range_start($value) {
        $this->start = (integer) $value;
        if (empty($this->start)) {
            $this->start = 0;
        }
        $this->start_infinity = false;
    }

    protected function set_range_end($value) {
        $this->end = (integer) $value;
        if (empty($this->end)) {
            $this->end = 0;
        }
        $this->end_infinity = false;
    }
}
