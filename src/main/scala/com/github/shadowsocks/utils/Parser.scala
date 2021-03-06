/*
 * Shadowsocks - A shadowsocks client for Android
 * Copyright (C) 2014 <max.c.lv@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *
 *                            ___====-_  _-====___
 *                      _--^^^#####//      \\#####^^^--_
 *                   _-^##########// (    ) \\##########^-_
 *                  -############//  |\^^/|  \\############-
 *                _/############//   (@::@)   \\############\_
 *               /#############((     \\//     ))#############\
 *              -###############\\    (oo)    //###############-
 *             -#################\\  / VV \  //#################-
 *            -###################\\/      \//###################-
 *           _#/|##########/\######(   /\   )######/\##########|\#_
 *           |/ |#/\#/\#/\/  \#/\##\  |  |  /##/\#/  \/\#/\#/\#| \|
 *           `  |/  V  V  `   V  \#\| |  | |/#/  V   '  V  V  \|  '
 *              `   `  `      `   / | |  | | \   '      '  '   '
 *                               (  | |  | |  )
 *                              __\ | |  | | /__
 *                             (vvv(VVV)(VVV)vvv)
 *
 *                              HERE BE DRAGONS
 *
 */

package com.github.shadowsocks.utils

import java.net.URLDecoder

import android.util.{Base64, Log}
import com.github.shadowsocks.database.Profile

object Parser {
  val TAG = "ShadowParser"
  private val pattern = "(?i)ss://([A-Za-z0-9+-/=_]+)(#(.+))?".r
  private val decodedPattern = "(?i)^((.+?)(-auth)??:(.*)@(.+?):(\\d+?))$".r

  private val pattern_ssr = "(?i)ssr://([A-Za-z0-9_=-]+)".r
  private val pattern_sub = "(?i)sub://([A-Za-z0-9_=-]+)".r
  private val decodedPattern_ssr = "(?i)^((.+):(\\d+?):(.*):(.+):(.*):([^/]+))".r
  private val decodedPattern_ssr_obfsparam = "(?i)[?&]obfsparam=([A-Za-z0-9_=-]*)".r
  private val decodedPattern_ssr_remarks = "(?i)[?&]remarks=([A-Za-z0-9_=+-]*)".r //原来没有+号进行过滤
  private val decodedPattern_ssr_protocolparam = "(?i)[?&]protoparam=([A-Za-z0-9_=-]*)".r
  private val decodedPattern_ssr_groupparam = "(?i)[?&]group=([A-Za-z0-9_=+-]*)".r

  def findUrlFromSub(data:CharSequence) = pattern_sub.findFirstMatchIn(if(data==null)""else data) match {
    case Some(sub_url)=>
      new String(Base64.decode(sub_url.group(1).replaceAll("=", ""), Base64.URL_SAFE), "UTF-8")
    case _ => null
  }

  def findAll(data: CharSequence) = pattern.findAllMatchIn(if (data == null) "" else data).map(m => try
    decodedPattern.findFirstMatchIn(new String(Base64.decode(m.group(1), Base64.NO_PADDING), "UTF-8")) match {
      case Some(ss) =>
        val profile = new Profile
        profile.method = ss.group(2).toLowerCase
        if (ss.group(3) != null) profile.protocol = "verify_sha1"
        profile.password = ss.group(4)
        profile.name = ss.group(5)
        profile.host = profile.name
        profile.remotePort = ss.group(6).toInt
        if (m.group(2) != null) profile.name = URLDecoder.decode(m.group(3), "utf-8")
        profile
      case _ => null
    }
    catch {
      case ex: Exception =>
        Log.e(TAG, "parser error: " + m.source, ex)// Ignore
        null
    }).filter(_ != null)

  def findAll_ssr(data: CharSequence) = pattern_ssr.findAllMatchIn(if (data == null) "" else data).map(m => try{
    val uri = new String(Base64.decode(m.group(1).replaceAll("=", ""), Base64.URL_SAFE), "UTF-8")
    decodedPattern_ssr.findFirstMatchIn(uri) match {
          case Some(ss) =>
            val profile = new Profile
            profile.host = ss.group(2).toLowerCase
            profile.remotePort = ss.group(3).toInt
            profile.protocol = ss.group(4).toLowerCase
            profile.method = ss.group(5).toLowerCase
            profile.obfs = ss.group(6).toLowerCase
            profile.password = new String(Base64.decode(ss.group(7).replaceAll("=", ""), Base64.URL_SAFE), "UTF-8")

            decodedPattern_ssr_obfsparam.findFirstMatchIn(uri) match {
              case Some(param) =>
                profile.obfs_param = new String(Base64.decode(param.group(1).replaceAll("=", ""), Base64.URL_SAFE), "UTF-8")
              case _ => null
            }

            decodedPattern_ssr_protocolparam.findFirstMatchIn(uri) match {
              case Some(param) =>
                profile.protocol_param = new String(Base64.decode(param.group(1).replaceAll("=", ""), Base64.URL_SAFE), "UTF-8")
              case _ => null
            }

            decodedPattern_ssr_remarks.findFirstMatchIn(uri) match {
              case Some(param) =>
                var str=param.group(1).replaceAll("=", "")
                var decodeStr= new String(Base64.decode(str, Base64.DEFAULT), "UTF-8");
//                Log.d(TAG,"xiaoliu parser name param is:"+param +":str:"+str+":decode:"+decodeStr)
                profile.name = decodeStr
              case _ => profile.name = ss.group(2).toLowerCase
            }

            decodedPattern_ssr_groupparam.findFirstMatchIn(uri) match {
              case Some(param) =>
                profile.url_group = new String(Base64.decode(param.group(1).replaceAll("=", ""), Base64.URL_SAFE), "UTF-8")
              case _ => null
            }

            profile
          case _ => null
        }
    }
    catch {
      case ex: Exception =>
        Log.e(TAG, "parser error: " + m.source, ex)// Ignore
        null
    }).filter(_ != null)
}
